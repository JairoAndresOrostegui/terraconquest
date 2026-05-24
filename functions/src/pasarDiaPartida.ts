import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { procesarPasoDiaPartida } from "./core/procesarPasoDia";

type PasoDiaData = {
  partidaId?: unknown;
};

function obtenerPartidaId(data: PasoDiaData): string {
  const valor = data.partidaId;
  if (typeof valor !== "string" || valor.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Falta partidaId.");
  }
  return valor.trim();
}

export const pasarDiaPartida = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const db = admin.firestore();
  const userId = request.auth.uid;
  const partidaId = obtenerPartidaId(request.data as PasoDiaData);
  const userSnap = await db.collection("usuarios").doc(userId).get();

  if (!userSnap.exists || userSnap.data()?.rol !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Solo un administrador puede ejecutar el paso de día manual."
    );
  }

  try {
    return await procesarPasoDiaPartida(partidaId);
  } catch (error) {
    throw new HttpsError(
      "internal",
      error instanceof Error
        ? error.message
        : "No se pudo completar el paso de día."
    );
  }
});
