import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

type MoverTropasData = {
  partidaId?: unknown;
  ciudadOrigenId?: unknown;
  ciudadDestinoId?: unknown;
  tropaId?: unknown;
  cantidad?: unknown;
};

function obtenerString(data: MoverTropasData, key: keyof MoverTropasData) {
  const valor = data[key];

  if (typeof valor !== "string" || valor.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Datos incompletos.");
  }

  return valor.trim();
}

function obtenerCantidad(valor: unknown): number {
  if (typeof valor !== "number" || !Number.isInteger(valor) || valor <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "La cantidad debe ser un número entero mayor a cero."
    );
  }

  return valor;
}

function numero(valor: unknown): number {
  if (typeof valor === "number" && Number.isFinite(valor)) return valor;
  return Number.parseInt(String(valor ?? "0"), 10) || 0;
}

export const moverTropasCiudad = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const db = admin.firestore();
  const data = request.data as MoverTropasData;
  const userId = request.auth.uid;
  const partidaId = obtenerString(data, "partidaId");
  const ciudadOrigenId = obtenerString(data, "ciudadOrigenId");
  const ciudadDestinoId = obtenerString(data, "ciudadDestinoId");
  const tropaId = obtenerString(data, "tropaId");
  const cantidad = obtenerCantidad(data.cantidad);

  if (ciudadOrigenId === ciudadDestinoId) {
    throw new HttpsError(
      "invalid-argument",
      "La ciudad origen y destino no pueden ser la misma."
    );
  }

  const partidaRef = db.collection("partidas").doc(partidaId);
  const origenRef = partidaRef.collection("ciudades").doc(ciudadOrigenId);
  const destinoRef = partidaRef.collection("ciudades").doc(ciudadDestinoId);

  return db.runTransaction(async (tx) => {
    const [partidaSnap, origenSnap, destinoSnap] = await Promise.all([
      tx.get(partidaRef),
      tx.get(origenRef),
      tx.get(destinoRef)
    ]);

    if (!partidaSnap.exists) {
      throw new HttpsError("not-found", "La partida no existe.");
    }

    const partida = partidaSnap.data() ?? {};

    if (partida.estado !== "activa") {
      throw new HttpsError("failed-precondition", "La partida no está activa.");
    }

    if (!origenSnap.exists || !destinoSnap.exists) {
      throw new HttpsError(
        "not-found",
        "La ciudad origen o destino no existe."
      );
    }

    const origen = origenSnap.data() ?? {};
    const destino = destinoSnap.data() ?? {};

    if (origen.userId !== userId || destino.userId !== userId) {
      throw new HttpsError(
        "permission-denied",
        "Solo puedes mover tropas entre tus propias ciudades."
      );
    }

    if (origen.imperioId !== destino.imperioId) {
      throw new HttpsError(
        "failed-precondition",
        "Las ciudades no pertenecen al mismo imperio."
      );
    }

    if (origen.estado !== "activa" || destino.estado !== "activa") {
      throw new HttpsError(
        "failed-precondition",
        "Ambas ciudades deben estar activas."
      );
    }

    const imperioId = typeof origen.imperioId === "string" ? origen.imperioId : "";
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

    const costeTurnos = 1;

    if (numero(imperio.turnos) < costeTurnos) {
      throw new HttpsError(
        "failed-precondition",
        "No tienes turnos suficientes."
      );
    }

    const tropaOrigenRef = origenRef.collection("tropas").doc(tropaId);
    const tropaDestinoRef = destinoRef.collection("tropas").doc(tropaId);
    const [tropaOrigenSnap, tropaDestinoSnap] = await Promise.all([
      tx.get(tropaOrigenRef),
      tx.get(tropaDestinoRef)
    ]);

    if (!tropaOrigenSnap.exists) {
      throw new HttpsError("not-found", "La ciudad origen no tiene esa tropa.");
    }

    const tropaOrigen = tropaOrigenSnap.data() ?? {};
    const cantidadOrigen = numero(tropaOrigen.cantidad);

    if (cantidadOrigen < cantidad) {
      throw new HttpsError(
        "failed-precondition",
        "No tienes suficientes tropas en la ciudad origen."
      );
    }

    const nivel = numero(tropaOrigen.nivel);
    const nivelesMover = nivel * cantidad;
    const limiteDestino =
      numero(destino.limiteTropas) || Math.floor(numero(destino.poblacion) * 2);
    const nivelesDestinoActuales = numero(
      destino.nivelesTropasDefensaActuales
    );
    const nuevosNivelesDestino = nivelesDestinoActuales + nivelesMover;

    if (nuevosNivelesDestino > limiteDestino) {
      throw new HttpsError(
        "failed-precondition",
        "La ciudad destino no tiene capacidad suficiente."
      );
    }

    const nuevaCantidadOrigen = cantidadOrigen - cantidad;
    const ahora = admin.firestore.FieldValue.serverTimestamp();

    if (nuevaCantidadOrigen <= 0) {
      tx.delete(tropaOrigenRef);
    } else {
      tx.update(tropaOrigenRef, {
        cantidad: nuevaCantidadOrigen,
        actualizadoEn: ahora
      });
    }

    const cantidadDestinoActual = tropaDestinoSnap.exists
      ? numero(tropaDestinoSnap.data()?.cantidad)
      : 0;

    tx.set(
      tropaDestinoRef,
      {
        ...tropaOrigen,
        tropaId,
        cantidad: cantidadDestinoActual + cantidad,
        asignacion: "defensa",
        actualizadoEn: ahora
      },
      { merge: true }
    );

    tx.update(origenRef, {
      totalTropas: admin.firestore.FieldValue.increment(-cantidad),
      nivelesTropasDefensaActuales:
        admin.firestore.FieldValue.increment(-nivelesMover),
      actualizadoEn: ahora
    });

    tx.update(destinoRef, {
      totalTropas: admin.firestore.FieldValue.increment(cantidad),
      nivelesTropasDefensaActuales: nuevosNivelesDestino,
      limiteTropas: limiteDestino,
      actualizadoEn: ahora
    });

    tx.update(imperioRef, {
      turnos: admin.firestore.FieldValue.increment(-costeTurnos),
      actualizadoEn: ahora
    });

    tx.set(partidaRef.collection("eventos").doc(), {
      tipo: "sistema",
      titulo: "Movimiento de tropas",
      descripcion: `Se movieron ${cantidad} unidades de ${tropaOrigen.nombre ?? tropaId}.`,
      ciudadId: ciudadOrigenId,
      ciudadDestinoId,
      imperioId,
      clanId: origen.clanId ?? null,
      visibleGlobal: false,
      visibleClanId: origen.clanId ?? null,
      dia: numero(partida.diaActual),
      creadoEn: ahora
    });

    return {
      ok: true,
      tropaId,
      cantidad,
      costeTurnos
    };
  });
});
