import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

type ComprarHeroeData = {
  partidaId?: unknown;
  imperioId?: unknown;
  ofertaHeroeId?: unknown;
  nombreHeroe?: unknown;
  regionId?: unknown;
};

function normalizarNombre(valor: string): string {
  return valor.trim().toLowerCase().replace(/\s+/g, " ");
}

function obtenerString(data: ComprarHeroeData, key: keyof ComprarHeroeData) {
  const valor = data[key];

  if (typeof valor !== "string" || valor.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Faltan datos obligatorios.");
  }

  return valor.trim();
}

function numero(valor: unknown): number {
  if (typeof valor === "number" && Number.isFinite(valor)) return valor;
  return Number.parseInt(String(valor ?? "0"), 10) || 0;
}

function mapaNumerico(valor: unknown): Record<string, number> {
  if (typeof valor !== "object" || valor === null || Array.isArray(valor)) {
    return {};
  }

  return Object.fromEntries(
    Object.entries(valor as Record<string, unknown>).map(([key, item]) => [
      key,
      numero(item)
    ])
  );
}

function calcularCapacidadNivelesTropas(nivel: number): number {
  return nivel * 1000;
}

export const comprarHeroe = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const db = admin.firestore();
  const data = request.data as ComprarHeroeData;
  const userId = request.auth.uid;
  const partidaId = obtenerString(data, "partidaId");
  const imperioId = obtenerString(data, "imperioId");
  const ofertaHeroeId = obtenerString(data, "ofertaHeroeId");
  const nombreHeroe = obtenerString(data, "nombreHeroe");
  const regionId = obtenerString(data, "regionId");
  const nombreLower = normalizarNombre(nombreHeroe);

  if (nombreLower.length < 3 || nombreLower.length > 30) {
    throw new HttpsError(
      "invalid-argument",
      "El nombre del héroe debe tener entre 3 y 30 caracteres."
    );
  }

  const partidaRef = db.collection("partidas").doc(partidaId);
  const imperioRef = partidaRef.collection("imperios").doc(imperioId);
  const ofertaRef = partidaRef.collection("heroesMercado").doc(ofertaHeroeId);
  const regionRef = partidaRef.collection("regiones").doc(regionId);

  return db.runTransaction(async (tx) => {
    const [partidaSnap, imperioSnap, ofertaSnap, regionSnap] =
      await Promise.all([
        tx.get(partidaRef),
        tx.get(imperioRef),
        tx.get(ofertaRef),
        tx.get(regionRef)
      ]);

    if (!partidaSnap.exists) {
      throw new HttpsError("not-found", "La partida no existe.");
    }

    if (!imperioSnap.exists) {
      throw new HttpsError("not-found", "El imperio no existe.");
    }

    if (!ofertaSnap.exists) {
      throw new HttpsError("not-found", "El héroe ya no está disponible.");
    }

    if (!regionSnap.exists) {
      throw new HttpsError("not-found", "La región no existe.");
    }

    const partida = partidaSnap.data() ?? {};
    const imperio = imperioSnap.data() ?? {};
    const oferta = ofertaSnap.data() ?? {};
    const region = regionSnap.data() ?? {};

    if (partida.estado !== "activa") {
      throw new HttpsError("failed-precondition", "La partida no está activa.");
    }

    if (imperio.userId !== userId) {
      throw new HttpsError(
        "permission-denied",
        "No puedes comprar héroes para este imperio."
      );
    }

    if (imperio.estado !== "activo") {
      throw new HttpsError("failed-precondition", "El imperio no está activo.");
    }

    if (oferta.disponible !== true) {
      throw new HttpsError(
        "failed-precondition",
        "Este héroe ya no está disponible."
      );
    }

    const precioOro = numero(oferta.precioOro);
    const recursos = mapaNumerico(imperio.recursos);

    if (numero(recursos.oro) < precioOro) {
      throw new HttpsError("failed-precondition", "No tienes oro suficiente.");
    }

    const nombreSnap = await tx.get(
      partidaRef.collection("heroes").where("nombreLower", "==", nombreLower).limit(1)
    );

    if (!nombreSnap.empty) {
      throw new HttpsError(
        "already-exists",
        "Ya existe un héroe con ese nombre."
      );
    }

    const heroeRef = partidaRef.collection("heroes").doc();
    const nuevosRecursos = {
      ...recursos,
      oro: numero(recursos.oro) - precioOro
    };
    const nivel = numero(oferta.nivel) || 1;
    const ahora = admin.firestore.FieldValue.serverTimestamp();

    tx.set(heroeRef, {
      imperioId,
      userId,
      partidaId,
      clanId: imperio.clanId ?? null,
      nombre: nombreHeroe.trim(),
      nombreLower,
      clase: oferta.clase ?? "guerrero",
      razaId: imperio.razaId ?? "",
      nivel,
      experiencia: 0,
      regionId,
      regionNumero: numero(region.numero),
      ciudadId: null,
      monturaId: null,
      ataque: numero(oferta.ataque),
      defensa: numero(oferta.defensa),
      danio: numero(oferta.danio),
      vida: numero(oferta.vida),
      velocidad: numero(oferta.velocidad),
      moral: numero(oferta.moral),
      puntosDesarrollo: numero(oferta.puntosDesarrollo),
      capacidadNivelesTropas: calcularCapacidadNivelesTropas(nivel),
      totalTropas: 0,
      nivelesTropasActuales: 0,
      tieneTropas: false,
      victorias: 0,
      capturado: false,
      capturadoPorImperioId: null,
      capturadoEn: null,
      costeRescate: 0,
      estado: "activo",
      creadoEn: ahora,
      actualizadoEn: ahora
    });

    tx.update(imperioRef, {
      recursos: nuevosRecursos,
      totalHeroes: admin.firestore.FieldValue.increment(1),
      actualizadoEn: ahora
    });

    tx.update(ofertaRef, {
      disponible: false,
      compradoPorImperioId: imperioId,
      compradoEn: ahora
    });

    tx.set(partidaRef.collection("eventos").doc(), {
      tipo: "sistema",
      titulo: "Héroe adquirido",
      descripcion: `${imperio.nombre ?? "Un imperio"} contrató al héroe ${nombreHeroe.trim()}.`,
      ciudadId: null,
      imperioId,
      clanId: imperio.clanId ?? null,
      visibleGlobal: false,
      visibleClanId: imperio.clanId ?? null,
      dia: numero(partida.diaActual),
      creadoEn: ahora
    });

    return {
      ok: true,
      heroeId: heroeRef.id,
      precioOro
    };
  });
});
