import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import {
  calcularProduccionCiudad,
  mapaNumerico,
  numero,
  recalcularProduccionImperio
} from "./core/calculoProduccion";

type EdificioConfig = {
  maxNivel: number;
  costeBase: Record<string, number>;
  turnosBase: number;
};

const edificiosConfig: Record<string, EdificioConfig> = {
  castillo: {
    maxNivel: 20,
    costeBase: { oro: 1000, madera: 500, piedra: 500 },
    turnosBase: 2
  },
  cuartel: {
    maxNivel: 20,
    costeBase: { oro: 800, madera: 400, piedra: 300 },
    turnosBase: 2
  },
  muralla: {
    maxNivel: 20,
    costeBase: { oro: 700, madera: 300, piedra: 700 },
    turnosBase: 2
  },
  minaOro: {
    maxNivel: 20,
    costeBase: { oro: 500, madera: 300, piedra: 300 },
    turnosBase: 1
  },
  cultivos: {
    maxNivel: 20,
    costeBase: { oro: 400, madera: 300, piedra: 100 },
    turnosBase: 1
  },
  pozos: {
    maxNivel: 20,
    costeBase: { oro: 400, madera: 200, piedra: 300 },
    turnosBase: 1
  },
  aserradero: {
    maxNivel: 20,
    costeBase: { oro: 500, madera: 200, piedra: 300 },
    turnosBase: 1
  },
  cantera: {
    maxNivel: 20,
    costeBase: { oro: 500, madera: 300, piedra: 200 },
    turnosBase: 1
  },
  almacen: {
    maxNivel: 20,
    costeBase: { oro: 600, madera: 400, piedra: 400 },
    turnosBase: 1
  }
};

type MejorarEdificioData = {
  partidaId?: unknown;
  ciudadId?: unknown;
  edificioId?: unknown;
};

function obtenerString(
  data: MejorarEdificioData,
  key: keyof MejorarEdificioData
): string {
  const valor = data[key];
  if (typeof valor !== "string" || valor.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Faltan datos obligatorios.");
  }
  return valor.trim();
}

function calcularCoste(
  costeBase: Record<string, number>,
  nivelActual: number
): Record<string, number> {
  const multiplicador = 1 + nivelActual * 0.35;
  const coste: Record<string, number> = {};

  for (const [recurso, valor] of Object.entries(costeBase)) {
    coste[recurso] = Math.round(valor * multiplicador);
  }

  return coste;
}

function tieneRecursos(
  recursos: Record<string, number>,
  coste: Record<string, number>
): boolean {
  for (const [recurso, cantidad] of Object.entries(coste)) {
    if ((recursos[recurso] ?? 0) < cantidad) return false;
  }

  return true;
}

export const mejorarEdificio = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const data = request.data as MejorarEdificioData;
  const userId = request.auth.uid;
  const partidaId = obtenerString(data, "partidaId");
  const ciudadId = obtenerString(data, "ciudadId");
  const edificioId = obtenerString(data, "edificioId");
  const config = edificiosConfig[edificioId];

  if (!config) {
    throw new HttpsError(
      "invalid-argument",
      "El edificio no existe o no está habilitado."
    );
  }

  const db = admin.firestore();
  const partidaRef = db.collection("partidas").doc(partidaId);
  const ciudadRef = partidaRef.collection("ciudades").doc(ciudadId);

  return db.runTransaction(async (tx) => {
    const [partidaSnap, ciudadSnap] = await Promise.all([
      tx.get(partidaRef),
      tx.get(ciudadRef)
    ]);

    if (!partidaSnap.exists) {
      throw new HttpsError("not-found", "La partida no existe.");
    }

    if (!ciudadSnap.exists) {
      throw new HttpsError("not-found", "La ciudad no existe.");
    }

    const partida = partidaSnap.data() ?? {};
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
    const terrenoId = typeof ciudad.terrenoId === "string" ? ciudad.terrenoId : "";
    const imperioRef = partidaRef.collection("imperios").doc(imperioId);
    const terrenoRef = db.collection("terrenos").doc(terrenoId);
    const [imperioSnap, terrenoSnap] = await Promise.all([
      tx.get(imperioRef),
      tx.get(terrenoRef)
    ]);

    if (!imperioSnap.exists) {
      throw new HttpsError("not-found", "El imperio no existe.");
    }

    if (!terrenoSnap.exists) {
      throw new HttpsError("not-found", "El terreno de la ciudad no existe.");
    }

    const imperio = imperioSnap.data() ?? {};
    const terreno = terrenoSnap.data() ?? {};

    const razaId = typeof imperio.razaId === "string" ? imperio.razaId : "";
    const razaRef = db.collection("razas").doc(razaId);
    const razaSnap = await tx.get(razaRef);

    if (!razaSnap.exists) {
      throw new HttpsError("not-found", "La raza del imperio no existe.");
    }

    const raza = razaSnap.data() ?? {};

    if (imperio.userId !== userId) {
      throw new HttpsError(
        "permission-denied",
        "No puedes modificar este imperio."
      );
    }

    const edificios = mapaNumerico(ciudad.edificios);
    const nivelActual = edificios[edificioId] ?? 0;

    if (nivelActual >= config.maxNivel) {
      throw new HttpsError(
        "failed-precondition",
        "El edificio ya está en su nivel máximo."
      );
    }

    const coste = calcularCoste(config.costeBase, nivelActual);
    const turnosNecesarios = config.turnosBase + Math.floor(nivelActual / 5);
    const turnosDisponibles = numero(imperio.turnos);

    if (turnosDisponibles < turnosNecesarios) {
      throw new HttpsError(
        "failed-precondition",
        "No tienes turnos suficientes."
      );
    }

    const recursos = mapaNumerico(imperio.recursos);

    if (!tieneRecursos(recursos, coste)) {
      throw new HttpsError(
        "failed-precondition",
        "No tienes recursos suficientes."
      );
    }

    const nuevosRecursos = { ...recursos };

    for (const [recurso, cantidad] of Object.entries(coste)) {
      nuevosRecursos[recurso] = (nuevosRecursos[recurso] ?? 0) - cantidad;
    }

    const nuevoNivel = nivelActual + 1;
    const nuevosEdificios = {
      ...edificios,
      [edificioId]: nuevoNivel
    };
    const calculoProduccion = calcularProduccionCiudad({
      ciudad,
      edificios: nuevosEdificios,
      terreno,
      raza
    });

    await recalcularProduccionImperio({
      tx,
      partidaRef,
      imperioRef,
      imperioId,
      ciudadActualizada: {
        ciudadId: ciudadRef.id,
        produccionDiaria: calculoProduccion.produccionDiaria,
        poblacion: numero(ciudad.poblacion),
        totalEdificios: numero(ciudad.totalEdificios) + 1
      }
    });
    const ahora = admin.firestore.FieldValue.serverTimestamp();

    tx.update(ciudadRef, {
      edificios: nuevosEdificios,
      produccionDiaria: calculoProduccion.produccionDiaria,
      consumoDiario: calculoProduccion.consumoDiario,
      crecimientoPoblacionDia: calculoProduccion.crecimientoPoblacionDia,
      totalEdificios: admin.firestore.FieldValue.increment(1),
      actualizadoEn: ahora
    });

    tx.update(imperioRef, {
      recursos: nuevosRecursos,
      turnos: admin.firestore.FieldValue.increment(-turnosNecesarios),
      actualizadoEn: ahora
    });

    tx.set(partidaRef.collection("eventos").doc(), {
      tipo: "sistema",
      titulo: "Edificio mejorado",
      descripcion: `Se mejoró ${edificioId} al nivel ${nuevoNivel}.`,
      imperioId,
      clanId: ciudad.clanId ?? null,
      visibleGlobal: false,
      visibleClanId: ciudad.clanId ?? null,
      dia: numero(partida.diaActual),
      creadoEn: ahora
    });

    return {
      edificioId,
      nuevoNivel,
      coste,
      turnosUsados: turnosNecesarios
    };
  });
});
