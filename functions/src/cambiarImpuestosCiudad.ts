import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import {
  calcularProduccionCiudad,
  mapaNumerico,
  numero,
  recalcularProduccionImperio
} from "./core/calculoProduccion";

type CambiarImpuestosData = {
  partidaId?: unknown;
  ciudadId?: unknown;
  impuestosPct?: unknown;
};

function obtenerString(data: CambiarImpuestosData, key: keyof CambiarImpuestosData) {
  const valor = data[key];

  if (typeof valor !== "string" || valor.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Datos incompletos.");
  }

  return valor.trim();
}

function obtenerImpuestos(valor: unknown): number {
  if (typeof valor !== "number" || !Number.isInteger(valor)) {
    throw new HttpsError(
      "invalid-argument",
      "El porcentaje de impuestos debe ser un número entero."
    );
  }

  if (valor < 0 || valor > 50) {
    throw new HttpsError(
      "invalid-argument",
      "El porcentaje de impuestos debe estar entre 0% y 50%."
    );
  }

  return valor;
}

export const cambiarImpuestosCiudad = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const db = admin.firestore();
  const data = request.data as CambiarImpuestosData;
  const userId = request.auth.uid;
  const partidaId = obtenerString(data, "partidaId");
  const ciudadId = obtenerString(data, "ciudadId");
  const impuestosPct = obtenerImpuestos(data.impuestosPct);
  const partidaRef = db.collection("partidas").doc(partidaId);
  const ciudadRef = partidaRef.collection("ciudades").doc(ciudadId);

  return db.runTransaction(async (tx) => {
    const ciudadSnap = await tx.get(ciudadRef);

    if (!ciudadSnap.exists) {
      throw new HttpsError("not-found", "La ciudad no existe.");
    }

    const ciudad = ciudadSnap.data() ?? {};

    if (ciudad.userId !== userId) {
      throw new HttpsError(
        "permission-denied",
        "No puedes modificar esta ciudad."
      );
    }

    if (ciudad.estado !== "activa") {
      throw new HttpsError(
        "failed-precondition",
        "Esta ciudad no está activa."
      );
    }

    const imperioId = typeof ciudad.imperioId === "string" ? ciudad.imperioId : "";
    const imperioRef = partidaRef.collection("imperios").doc(imperioId);
    const imperioSnap = await tx.get(imperioRef);

    if (!imperioSnap.exists) {
      throw new HttpsError("not-found", "El imperio no existe.");
    }

    const imperio = imperioSnap.data() ?? {};

    if (imperio.userId !== userId) {
      throw new HttpsError(
        "permission-denied",
        "No puedes modificar este imperio."
      );
    }

    const terrenoId = typeof ciudad.terrenoId === "string" ? ciudad.terrenoId : "";
    const razaId = typeof imperio.razaId === "string" ? imperio.razaId : "";
    const terrenoRef = db.collection("terrenos").doc(terrenoId);
    const razaRef = db.collection("razas").doc(razaId);
    const [terrenoSnap, razaSnap] = await Promise.all([
      tx.get(terrenoRef),
      tx.get(razaRef)
    ]);

    if (!terrenoSnap.exists || !razaSnap.exists) {
      throw new HttpsError(
        "not-found",
        "Datos incompletos para recalcular la ciudad."
      );
    }

    const ciudadActualizada = {
      ...ciudad,
      impuestosPct
    };
    const calculo = calcularProduccionCiudad({
      ciudad: ciudadActualizada,
      edificios: mapaNumerico(ciudad.edificios),
      terreno: terrenoSnap.data() ?? {},
      raza: razaSnap.data() ?? {}
    });

    await recalcularProduccionImperio({
      tx,
      partidaRef,
      imperioRef,
      imperioId,
      ciudadActualizada: {
        ciudadId: ciudadRef.id,
        produccionDiaria: calculo.produccionDiaria,
        poblacion: numero(ciudad.poblacion),
        totalEdificios: numero(ciudad.totalEdificios)
      }
    });

    tx.update(ciudadRef, {
      impuestosPct,
      produccionDiaria: calculo.produccionDiaria,
      consumoDiario: calculo.consumoDiario,
      crecimientoPoblacionDia: calculo.crecimientoPoblacionDia,
      actualizadoEn: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      ok: true,
      impuestosPct
    };
  });
});
