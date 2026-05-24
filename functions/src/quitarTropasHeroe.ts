import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

type QuitarTropasHeroeData = {
  partidaId?: unknown;
  heroeId?: unknown;
  ciudadDestinoId?: unknown;
  tropaId?: unknown;
  cantidad?: unknown;
};

function obtenerString(
  data: QuitarTropasHeroeData,
  key: keyof QuitarTropasHeroeData
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

export const quitarTropasHeroe = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const db = admin.firestore();
  const data = request.data as QuitarTropasHeroeData;
  const userId = request.auth.uid;
  const partidaId = obtenerString(data, "partidaId");
  const heroeId = obtenerString(data, "heroeId");
  const ciudadDestinoId = obtenerString(data, "ciudadDestinoId");
  const tropaId = obtenerString(data, "tropaId");
  const cantidad = obtenerCantidad(data.cantidad);
  const partidaRef = db.collection("partidas").doc(partidaId);
  const heroeRef = partidaRef.collection("heroes").doc(heroeId);
  const ciudadDestinoRef = partidaRef
    .collection("ciudades")
    .doc(ciudadDestinoId);
  const tropaHeroeRef = heroeRef.collection("tropas").doc(tropaId);
  const tropaCiudadRef = ciudadDestinoRef.collection("tropas").doc(tropaId);

  return db.runTransaction(async (tx) => {
    const [
      partidaSnap,
      heroeSnap,
      ciudadDestinoSnap,
      tropaHeroeSnap,
      tropaCiudadSnap
    ] = await Promise.all([
      tx.get(partidaRef),
      tx.get(heroeRef),
      tx.get(ciudadDestinoRef),
      tx.get(tropaHeroeRef),
      tx.get(tropaCiudadRef)
    ]);

    if (!partidaSnap.exists) {
      throw new HttpsError("not-found", "La partida no existe.");
    }

    if (!heroeSnap.exists) {
      throw new HttpsError("not-found", "El héroe no existe.");
    }

    if (!ciudadDestinoSnap.exists) {
      throw new HttpsError("not-found", "La ciudad destino no existe.");
    }

    if (!tropaHeroeSnap.exists) {
      throw new HttpsError("not-found", "El héroe no tiene esa tropa.");
    }

    const partida = partidaSnap.data() ?? {};
    const heroe = heroeSnap.data() ?? {};
    const ciudadDestino = ciudadDestinoSnap.data() ?? {};
    const tropaHeroe = tropaHeroeSnap.data() ?? {};

    if (partida.estado !== "activa") {
      throw new HttpsError("failed-precondition", "La partida no está activa.");
    }

    if (heroe.userId !== userId || ciudadDestino.userId !== userId) {
      throw new HttpsError(
        "permission-denied",
        "Solo puedes mover tus propias tropas."
      );
    }

    if (heroe.imperioId !== ciudadDestino.imperioId) {
      throw new HttpsError(
        "failed-precondition",
        "El héroe y la ciudad no pertenecen al mismo imperio."
      );
    }

    if (heroe.regionId !== ciudadDestino.regionId) {
      throw new HttpsError(
        "failed-precondition",
        "El héroe debe estar en la misma región que la ciudad destino."
      );
    }

    if (heroe.estado !== "activo" || heroe.capturado === true) {
      throw new HttpsError(
        "failed-precondition",
        "El héroe no está disponible."
      );
    }

    if (ciudadDestino.estado !== "activa") {
      throw new HttpsError(
        "failed-precondition",
        "La ciudad destino no está activa."
      );
    }

    const cantidadHeroe = numero(tropaHeroe.cantidad);

    if (cantidadHeroe < cantidad) {
      throw new HttpsError(
        "failed-precondition",
        "El héroe no tiene suficientes tropas."
      );
    }

    const nivelesMover = numero(tropaHeroe.nivel) * cantidad;
    const limiteDestino =
      numero(ciudadDestino.limiteTropas) ||
      Math.floor(numero(ciudadDestino.poblacion) * 2);
    const nivelesDestinoActuales = numero(
      ciudadDestino.nivelesTropasDefensaActuales
    );
    const nuevosNivelesDestino = nivelesDestinoActuales + nivelesMover;

    if (nuevosNivelesDestino > limiteDestino) {
      throw new HttpsError(
        "failed-precondition",
        "La ciudad destino no tiene capacidad suficiente."
      );
    }

    const nuevaCantidadHeroe = cantidadHeroe - cantidad;
    const ahora = admin.firestore.FieldValue.serverTimestamp();

    if (nuevaCantidadHeroe <= 0) {
      tx.delete(tropaHeroeRef);
    } else {
      tx.update(tropaHeroeRef, {
        cantidad: nuevaCantidadHeroe,
        actualizadoEn: ahora
      });
    }

    const cantidadCiudadActual = tropaCiudadSnap.exists
      ? numero(tropaCiudadSnap.data()?.cantidad)
      : 0;

    tx.set(
      tropaCiudadRef,
      {
        ...tropaHeroe,
        tropaId,
        cantidad: cantidadCiudadActual + cantidad,
        asignacion: "defensa",
        actualizadoEn: ahora
      },
      { merge: true }
    );

    const nuevosNivelesHeroe = Math.max(
      0,
      numero(heroe.nivelesTropasActuales) - nivelesMover
    );

    tx.update(heroeRef, {
      totalTropas: admin.firestore.FieldValue.increment(-cantidad),
      nivelesTropasActuales: nuevosNivelesHeroe,
      tieneTropas: nuevosNivelesHeroe > 0,
      actualizadoEn: ahora
    });

    tx.update(ciudadDestinoRef, {
      totalTropas: admin.firestore.FieldValue.increment(cantidad),
      nivelesTropasDefensaActuales: nuevosNivelesDestino,
      limiteTropas: limiteDestino,
      actualizadoEn: ahora
    });

    tx.set(partidaRef.collection("eventos").doc(), {
      tipo: "sistema",
      titulo: "Tropas retiradas de héroe",
      descripcion: `Se retiraron ${cantidad} unidades de ${tropaHeroe.nombre ?? tropaId} del héroe ${heroe.nombre ?? heroeId}.`,
      ciudadId: ciudadDestinoId,
      heroeId,
      imperioId: heroe.imperioId,
      clanId: heroe.clanId ?? null,
      visibleGlobal: false,
      visibleClanId: heroe.clanId ?? null,
      dia: numero(partida.diaActual),
      creadoEn: ahora
    });

    return {
      ok: true,
      heroeId,
      tropaId,
      cantidad,
      nivelesHeroe: nuevosNivelesHeroe,
      capacidadCiudad: limiteDestino,
      nivelesCiudad: nuevosNivelesDestino
    };
  });
});
