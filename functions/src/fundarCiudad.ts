import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import {
  calcularProduccionCiudad,
  numero,
  recalcularProduccionImperio
} from "./core/calculoProduccion";

type FundarCiudadData = {
  partidaId?: unknown;
  imperioId?: unknown;
  nombreCiudad?: unknown;
  regionId?: unknown;
  terrenoId?: unknown;
};

const edificiosIniciales: Record<string, number> = {
  castillo: 1,
  muralla: 0,
  armeria: 0,
  foso: 0,
  cuartel: 0,
  torreMagica: 0,
  universidad: 0,
  santuario: 0,
  templo: 0,
  mercado: 0,
  mercadoNegro: 0,
  minaOro: 0,
  minaPlata: 0,
  minaHierro: 0,
  minaPiedra: 0,
  minaMithril: 0,
  aserradero: 0,
  cultivos: 0,
  yacimientos: 0,
  pozos: 0,
  taller: 0,
  forjaHierro: 0,
  forjaMithril: 0,
  joyeria: 0,
  camaraCristal: 0,
  cantera: 0,
  carpinteria: 0,
  monumentos: 0,
  acueducto: 0,
  almacen: 0,
  coliseo: 0,
  burdeles: 0,
  escuela: 0
};

function normalizarNombre(valor: string): string {
  return valor.trim().toLowerCase().replace(/\s+/g, " ");
}

function obtenerString(data: FundarCiudadData, key: keyof FundarCiudadData) {
  const valor = data[key];

  if (typeof valor !== "string" || valor.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Faltan datos obligatorios.");
  }

  return valor.trim();
}

function listaStrings(valor: unknown): string[] {
  if (!Array.isArray(valor)) return [];
  return valor.filter((item): item is string => typeof item === "string");
}

export const fundarCiudad = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const db = admin.firestore();
  const data = request.data as FundarCiudadData;
  const userId = request.auth.uid;
  const partidaId = obtenerString(data, "partidaId");
  const imperioId = obtenerString(data, "imperioId");
  const nombreCiudad = obtenerString(data, "nombreCiudad");
  const regionId = obtenerString(data, "regionId");
  const terrenoId = obtenerString(data, "terrenoId");
  const nombreCiudadLower = normalizarNombre(nombreCiudad);

  if (nombreCiudadLower.length < 3 || nombreCiudadLower.length > 30) {
    throw new HttpsError(
      "invalid-argument",
      "El nombre de la ciudad debe tener entre 3 y 30 caracteres."
    );
  }

  const partidaRef = db.collection("partidas").doc(partidaId);
  const imperioRef = partidaRef.collection("imperios").doc(imperioId);
  const regionRef = partidaRef.collection("regiones").doc(regionId);
  const terrenoRef = db.collection("terrenos").doc(terrenoId);
  const ciudadesRef = partidaRef.collection("ciudades");

  return db.runTransaction(async (tx) => {
    const [partidaSnap, imperioSnap, regionSnap, terrenoSnap] =
      await Promise.all([
        tx.get(partidaRef),
        tx.get(imperioRef),
        tx.get(regionRef),
        tx.get(terrenoRef)
      ]);

    if (!partidaSnap.exists) {
      throw new HttpsError("not-found", "La partida no existe.");
    }

    if (!imperioSnap.exists) {
      throw new HttpsError("not-found", "El imperio no existe.");
    }

    if (!regionSnap.exists) {
      throw new HttpsError("not-found", "La región no existe.");
    }

    if (!terrenoSnap.exists) {
      throw new HttpsError("not-found", "El terreno no existe.");
    }

    const partida = partidaSnap.data() ?? {};
    const imperio = imperioSnap.data() ?? {};
    const region = regionSnap.data() ?? {};
    const terreno = terrenoSnap.data() ?? {};

    if (partida.estado !== "activa") {
      throw new HttpsError(
        "failed-precondition",
        "Solo puedes fundar ciudades en partidas activas."
      );
    }

    if (imperio.userId !== userId) {
      throw new HttpsError(
        "permission-denied",
        "No puedes fundar ciudades en este imperio."
      );
    }

    if (imperio.estado !== "activo") {
      throw new HttpsError("failed-precondition", "El imperio no está activo.");
    }

    const terrenosPermitidos = listaStrings(region.terrenosPermitidos);
    const codigoTerreno =
      typeof terreno.codigo === "string" ? terreno.codigo : "";

    if (
      !terrenosPermitidos.includes(terrenoId) &&
      !terrenosPermitidos.includes(codigoTerreno)
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Este terreno no está permitido en la región seleccionada."
      );
    }

    const ciudadNombreSnap = await tx.get(
      ciudadesRef.where("nombreLower", "==", nombreCiudadLower).limit(1)
    );

    if (!ciudadNombreSnap.empty) {
      throw new HttpsError(
        "already-exists",
        "Ya existe una ciudad con ese nombre."
      );
    }

    const totalCiudadesActual = numero(imperio.totalCiudades);
    const costeTurnos = 50 + totalCiudadesActual * 25;

    if (numero(imperio.turnos) < costeTurnos) {
      throw new HttpsError(
        "failed-precondition",
        "No tienes turnos suficientes para fundar esta ciudad."
      );
    }

    const razaId = typeof imperio.razaId === "string" ? imperio.razaId : "";
    const razaRef = db.collection("razas").doc(razaId);
    const razaSnap = await tx.get(razaRef);

    if (!razaSnap.exists) {
      throw new HttpsError("not-found", "La raza del imperio no existe.");
    }

    const raza = razaSnap.data() ?? {};
    const ciudadRef = ciudadesRef.doc();
    const ciudadBase = {
      imperioId,
      userId,
      partidaId,
      clanId: imperio.clanId ?? null,
      nombre: nombreCiudad.trim(),
      nombreLower: nombreCiudadLower,
      numeroCiudad: numero(partida.contadorCiudades) + 1,
      regionId,
      regionNumero: numero(region.numero),
      terrenoId,
      poblacion: 500,
      estado: "activa",
      proteccionHasta: null,
      moral: 100,
      corrupcion: 0,
      felicidad: 100,
      higiene: 100,
      desempleo: 0,
      religion: 0,
      cultura: 0,
      impuestosPct: 10,
      sistemaDefensivoId: "normal",
      edificios: edificiosIniciales,
      nivelesTropasDefensaActuales: 0,
      nivelesTropasDefensaMinimos: 0,
      limiteTropas: 0,
      totalEdificios: 1
    };
    const calculo = calcularProduccionCiudad({
      ciudad: ciudadBase,
      edificios: edificiosIniciales,
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
        produccionDiaria: calculo.produccionDiaria,
        poblacion: ciudadBase.poblacion,
        totalEdificios: ciudadBase.totalEdificios
      }
    });

    const ahora = admin.firestore.FieldValue.serverTimestamp();

    tx.set(ciudadRef, {
      ...ciudadBase,
      produccionDiaria: calculo.produccionDiaria,
      consumoDiario: calculo.consumoDiario,
      crecimientoPoblacionDia: calculo.crecimientoPoblacionDia,
      creadoEn: ahora,
      actualizadoEn: ahora,
      conquistadaEn: null
    });

    tx.update(partidaRef, {
      contadorCiudades: admin.firestore.FieldValue.increment(1),
      actualizadoEn: ahora
    });

    tx.update(imperioRef, {
      turnos: admin.firestore.FieldValue.increment(-costeTurnos),
      actualizadoEn: ahora
    });

    tx.set(partidaRef.collection("eventos").doc(), {
      tipo: "sistema",
      titulo: "Nueva ciudad fundada",
      descripcion: `${imperio.nombre ?? "Un imperio"} fundó la ciudad ${nombreCiudad.trim()}.`,
      imperioId,
      clanId: imperio.clanId ?? null,
      visibleGlobal: false,
      visibleClanId: imperio.clanId ?? null,
      dia: numero(partida.diaActual),
      creadoEn: ahora
    });

    return {
      ciudadId: ciudadRef.id,
      costeTurnos
    };
  });
});
