import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

type AsignarTropasHeroeData = {
  partidaId?: unknown;
  ciudadId?: unknown;
  heroeId?: unknown;
  tropaId?: unknown;
  cantidad?: unknown;
};

function obtenerString(
  data: AsignarTropasHeroeData,
  key: keyof AsignarTropasHeroeData
) {
  const valor = data[key];

  if (typeof valor !== "string" || valor.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Datos incompletos.");
  }

  return valor.trim();
}

function obtenerCantidad(valor: unknown): number {
  if (typeof valor !== "number" || !Number.isInteger(valor) || valor <= 0) {
    throw new HttpsError("invalid-argument", "Cantidad inválida.");
  }

  return valor;
}

function numero(valor: unknown): number {
  if (typeof valor === "number" && Number.isFinite(valor)) return valor;
  return Number.parseInt(String(valor ?? "0"), 10) || 0;
}

export const asignarTropasHeroe = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const db = admin.firestore();
  const data = request.data as AsignarTropasHeroeData;
  const userId = request.auth.uid;
  const partidaId = obtenerString(data, "partidaId");
  const ciudadId = obtenerString(data, "ciudadId");
  const heroeId = obtenerString(data, "heroeId");
  const tropaId = obtenerString(data, "tropaId");
  const cantidad = obtenerCantidad(data.cantidad);
  const partidaRef = db.collection("partidas").doc(partidaId);
  const ciudadRef = partidaRef.collection("ciudades").doc(ciudadId);
  const heroeRef = partidaRef.collection("heroes").doc(heroeId);
  const tropaCiudadRef = ciudadRef.collection("tropas").doc(tropaId);
  const tropaHeroeRef = heroeRef.collection("tropas").doc(tropaId);

  return db.runTransaction(async (tx) => {
    const [
      partidaSnap,
      ciudadSnap,
      heroeSnap,
      tropaCiudadSnap,
      tropaHeroeSnap
    ] = await Promise.all([
      tx.get(partidaRef),
      tx.get(ciudadRef),
      tx.get(heroeRef),
      tx.get(tropaCiudadRef),
      tx.get(tropaHeroeRef)
    ]);

    if (!partidaSnap.exists) {
      throw new HttpsError("not-found", "La partida no existe.");
    }

    if (!ciudadSnap.exists) {
      throw new HttpsError("not-found", "La ciudad no existe.");
    }

    if (!heroeSnap.exists) {
      throw new HttpsError("not-found", "El héroe no existe.");
    }

    if (!tropaCiudadSnap.exists) {
      throw new HttpsError("not-found", "La ciudad no tiene esa tropa.");
    }

    const partida = partidaSnap.data() ?? {};
    const ciudad = ciudadSnap.data() ?? {};
    const heroe = heroeSnap.data() ?? {};
    const tropaCiudad = tropaCiudadSnap.data() ?? {};

    if (partida.estado !== "activa") {
      throw new HttpsError("failed-precondition", "La partida no está activa.");
    }

    if (ciudad.userId !== userId || heroe.userId !== userId) {
      throw new HttpsError(
        "permission-denied",
        "No puedes mover estas tropas."
      );
    }

    if (ciudad.imperioId !== heroe.imperioId) {
      throw new HttpsError(
        "failed-precondition",
        "La ciudad y el héroe no pertenecen al mismo imperio."
      );
    }

    if (ciudad.regionId !== heroe.regionId) {
      throw new HttpsError(
        "failed-precondition",
        "El héroe debe estar en la misma región que la ciudad."
      );
    }

    if (heroe.estado !== "activo" || heroe.capturado === true) {
      throw new HttpsError(
        "failed-precondition",
        "El héroe no está disponible."
      );
    }

    const cantidadCiudad = numero(tropaCiudad.cantidad);

    if (cantidadCiudad < cantidad) {
      throw new HttpsError(
        "failed-precondition",
        "No hay suficientes tropas en la ciudad."
      );
    }

    const nivel = numero(tropaCiudad.nivel);
    const nivelesMover = nivel * cantidad;
    const capacidad = numero(heroe.capacidadNivelesTropas);
    const nivelesActuales = numero(heroe.nivelesTropasActuales);
    const nuevosNiveles = nivelesActuales + nivelesMover;

    if (nuevosNiveles > capacidad) {
      throw new HttpsError(
        "failed-precondition",
        "El héroe no tiene capacidad suficiente."
      );
    }

    const nuevaCantidadCiudad = cantidadCiudad - cantidad;
    const ahora = admin.firestore.FieldValue.serverTimestamp();

    if (nuevaCantidadCiudad <= 0) {
      tx.delete(tropaCiudadRef);
    } else {
      tx.update(tropaCiudadRef, {
        cantidad: nuevaCantidadCiudad,
        actualizadoEn: ahora
      });
    }

    const cantidadHeroeActual = tropaHeroeSnap.exists
      ? numero(tropaHeroeSnap.data()?.cantidad)
      : 0;

    tx.set(
      tropaHeroeRef,
      {
        ...tropaCiudad,
        tropaId,
        cantidad: cantidadHeroeActual + cantidad,
        asignacion: "heroe",
        actualizadoEn: ahora
      },
      { merge: true }
    );

    tx.update(ciudadRef, {
      totalTropas: admin.firestore.FieldValue.increment(-cantidad),
      nivelesTropasDefensaActuales:
        admin.firestore.FieldValue.increment(-nivelesMover),
      actualizadoEn: ahora
    });

    tx.update(heroeRef, {
      totalTropas: admin.firestore.FieldValue.increment(cantidad),
      nivelesTropasActuales: nuevosNiveles,
      tieneTropas: true,
      actualizadoEn: ahora
    });

    tx.set(partidaRef.collection("eventos").doc(), {
      tipo: "sistema",
      titulo: "Tropas asignadas a héroe",
      descripcion: `Se asignaron ${cantidad} unidades de ${tropaCiudad.nombre ?? tropaId} al héroe ${heroe.nombre ?? heroeId}.`,
      ciudadId,
      heroeId,
      imperioId: ciudad.imperioId,
      clanId: ciudad.clanId ?? null,
      visibleGlobal: false,
      visibleClanId: ciudad.clanId ?? null,
      dia: numero(partida.diaActual),
      creadoEn: ahora
    });

    return {
      ok: true,
      heroeId,
      tropaId,
      cantidad,
      nivelesHeroe: nuevosNiveles,
      capacidadHeroe: capacidad
    };
  });
});
