import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { calcularProduccionCiudad } from "./core/calculoProduccion";

const recursosIniciales = {
  oro: 10000,
  alimentos: 5000,
  agua: 5000,
  madera: 5000,
  piedra: 3000,
  hierro: 1000,
  herramientas: 0,
  armas: 0,
  bloques: 0,
  tablas: 0,
  mithril: 0,
  cristal: 0,
  plata: 0,
  reliquias: 0,
  gemas: 0,
  joyas: 0,
  mana: 0,
  karma: 0
};

const edificiosIniciales = {
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

type CrearImperioData = {
  partidaId?: unknown;
  razaId?: unknown;
  nombreImperio?: unknown;
  nombreCiudad?: unknown;
  regionId?: unknown;
  terrenoId?: unknown;
};

function normalizarNombre(valor: string): string {
  return valor.trim().toLowerCase().replace(/\s+/g, " ");
}

function obtenerString(data: CrearImperioData, key: keyof CrearImperioData): string {
  const valor = data[key];
  if (typeof valor !== "string" || valor.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Faltan datos obligatorios.");
  }
  return valor.trim();
}

function validarNombre(nombreLower: string, mensaje: string): void {
  if (nombreLower.length < 3 || nombreLower.length > 30) {
    throw new HttpsError("invalid-argument", mensaje);
  }
}

function obtenerNumero(valor: unknown, fallback = 0): number {
  return typeof valor === "number" && Number.isFinite(valor) ? valor : fallback;
}

function obtenerListaStrings(valor: unknown): string[] {
  return Array.isArray(valor) ? valor.map((item) => String(item)) : [];
}

export const crearImperio = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const db = admin.firestore();
  const userId = request.auth.uid;
  const data = request.data as CrearImperioData;

  const partidaId = obtenerString(data, "partidaId");
  const razaId = obtenerString(data, "razaId");
  const nombreImperio = obtenerString(data, "nombreImperio");
  const nombreCiudad = obtenerString(data, "nombreCiudad");
  const regionId = obtenerString(data, "regionId");
  const terrenoId = obtenerString(data, "terrenoId");

  const nombreImperioLower = normalizarNombre(nombreImperio);
  const nombreCiudadLower = normalizarNombre(nombreCiudad);

  validarNombre(
    nombreImperioLower,
    "El nombre del imperio debe tener entre 3 y 30 caracteres."
  );
  validarNombre(
    nombreCiudadLower,
    "El nombre de la ciudad debe tener entre 3 y 30 caracteres."
  );

  const partidaRef = db.collection("partidas").doc(partidaId);
  const razaRef = db.collection("razas").doc(razaId);
  const regionRef = db.collection("regiones").doc(regionId);
  const terrenoRef = db.collection("terrenos").doc(terrenoId);

  return db.runTransaction(async (tx) => {
    const [partidaSnap, razaSnap, regionSnap, terrenoSnap] = await Promise.all([
      tx.get(partidaRef),
      tx.get(razaRef),
      tx.get(regionRef),
      tx.get(terrenoRef)
    ]);

    if (!partidaSnap.exists) {
      throw new HttpsError("not-found", "La partida no existe.");
    }
    if (!razaSnap.exists) {
      throw new HttpsError("not-found", "La raza seleccionada no existe.");
    }
    if (!regionSnap.exists) {
      throw new HttpsError("not-found", "La región seleccionada no existe.");
    }
    if (!terrenoSnap.exists) {
      throw new HttpsError("not-found", "El terreno seleccionado no existe.");
    }

    const partida = partidaSnap.data() ?? {};
    const raza = razaSnap.data() ?? {};
    const region = regionSnap.data() ?? {};
    const terreno = terrenoSnap.data() ?? {};

    if (partida.estado !== "futura" && partida.estado !== "activa") {
      throw new HttpsError(
        "failed-precondition",
        "Esta partida no permite crear imperios."
      );
    }
    if (partida.permitirRegistro !== true) {
      throw new HttpsError(
        "failed-precondition",
        "El registro está cerrado para esta partida."
      );
    }

    const regionesDisponibles = obtenerListaStrings(partida.regionesDisponibles);
    if (!regionesDisponibles.includes(regionId)) {
      throw new HttpsError(
        "failed-precondition",
        "La regiÃ³n seleccionada no estÃ¡ disponible en esta partida."
      );
    }

    const terrenosPermitidos = obtenerListaStrings(region.terrenosPermitidos);
    const codigoTerreno = typeof terreno.codigo === "string" ? terreno.codigo : "";

    if (
      terrenosPermitidos.length > 0 &&
      !terrenosPermitidos.includes(terrenoId) &&
      !terrenosPermitidos.includes(codigoTerreno)
    ) {
      throw new HttpsError(
        "failed-precondition",
        "El terreno seleccionado no está permitido en esta región."
      );
    }

    const imperiosRef = partidaRef.collection("imperios");
    const ciudadesRef = partidaRef.collection("ciudades");

    const [imperioUsuarioSnap, imperioNombreSnap, ciudadNombreSnap] =
      await Promise.all([
        tx.get(imperiosRef.where("userId", "==", userId).limit(1)),
        tx.get(
          imperiosRef.where("nombreLower", "==", nombreImperioLower).limit(1)
        ),
        tx.get(
          ciudadesRef.where("nombreLower", "==", nombreCiudadLower).limit(1)
        )
      ]);

    if (!imperioUsuarioSnap.empty) {
      throw new HttpsError(
        "already-exists",
        "Ya tienes un imperio en esta partida."
      );
    }
    if (!imperioNombreSnap.empty) {
      throw new HttpsError(
        "already-exists",
        "Ya existe un imperio con ese nombre."
      );
    }
    if (!ciudadNombreSnap.empty) {
      throw new HttpsError(
        "already-exists",
        "Ya existe una ciudad con ese nombre."
      );
    }

    const imperioRef = imperiosRef.doc();
    const ciudadRef = ciudadesRef.doc();
    const ahora = admin.firestore.FieldValue.serverTimestamp();
    const diaActual = obtenerNumero(partida.diaActual);
    const numeroImperio = obtenerNumero(partida.contadorImperios) + 1;
    const numeroCiudad = obtenerNumero(partida.contadorCiudades) + 1;
    const regionCodigo = typeof region.codigo === "string" ? region.codigo : "";
    const ciudadBase = {
      imperioId: imperioRef.id,
      userId,
      clanId: null,
      nombre: nombreCiudad.trim(),
      nombreLower: nombreCiudadLower,
      numeroCiudad,
      regionId,
      regionCodigo,
      regionBonos:
        typeof region.bonos === "object" &&
        region.bonos !== null &&
        !Array.isArray(region.bonos)
          ? region.bonos
          : {},
      terrenoId,
      poblacion: 1000,
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
      nivelesTropasDefensaActuales: 0,
      nivelesTropasDefensaMinimos: 0,
      limiteTropas: 0,
      edificios: edificiosIniciales,
      totalEdificios: 1
    };
    const calculo = calcularProduccionCiudad({
      ciudad: ciudadBase,
      edificios: edificiosIniciales,
      terreno,
      raza,
      region
    });

    tx.set(imperioRef, {
      userId,
      nombre: nombreImperio.trim(),
      nombreLower: nombreImperioLower,
      razaId,
      clanId: null,
      estado: "activo",
      numeroImperio,
      diaCreacion: diaActual,
      proteccionHasta: null,
      recursos: recursosIniciales,
      produccionDiaria: calculo.produccionDiaria,
      turnos: 100,
      turnosGeneradosDia: 0,
      fama: 0,
      indiceBelico: 0,
      valor: 0,
      valorSinVictoriasHeroes: 0,
      ranking: 0,
      rankingAnterior: 0,
      totalCiudades: 1,
      totalHeroes: 0,
      totalPoblacion: 1000,
      totalEdificios: 1,
      totalTropas: 0,
      creadoEn: ahora,
      actualizadoEn: ahora
    });

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
      contadorImperios: numeroImperio,
      contadorCiudades: numeroCiudad,
      actualizadoEn: ahora
    });

    tx.set(partidaRef.collection("eventos").doc(), {
      tipo: "sistema",
      titulo: "Nuevo imperio creado",
      descripcion: `${nombreImperio.trim()} ha surgido en la partida.`,
      imperioId: imperioRef.id,
      clanId: null,
      visibleGlobal: true,
      visibleClanId: null,
      dia: diaActual,
      creadoEn: ahora
    });

    return {
      imperioId: imperioRef.id,
      ciudadId: ciudadRef.id
    };
  });
});
