import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

type ObtenerTropasDisponiblesData = {
  partidaId?: unknown;
  ciudadId?: unknown;
};

function obtenerString(
  data: ObtenerTropasDisponiblesData,
  key: keyof ObtenerTropasDisponiblesData
) {
  const valor = data[key];

  if (typeof valor !== "string" || valor.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Datos incompletos.");
  }

  return valor.trim();
}

function numero(valor: unknown): number {
  if (typeof valor === "number" && Number.isFinite(valor)) return valor;
  return Number.parseInt(String(valor ?? "0"), 10) || 0;
}

export const obtenerTropasDisponibles = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const db = admin.firestore();
  const data = request.data as ObtenerTropasDisponiblesData;
  const userId = request.auth.uid;
  const partidaId = obtenerString(data, "partidaId");
  const ciudadId = obtenerString(data, "ciudadId");
  const partidaRef = db.collection("partidas").doc(partidaId);
  const ciudadRef = partidaRef.collection("ciudades").doc(ciudadId);
  const [partidaSnap, ciudadSnap] = await Promise.all([
    partidaRef.get(),
    ciudadRef.get()
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
      "No puedes consultar tropas para esta ciudad."
    );
  }

  const imperioId = typeof ciudad.imperioId === "string" ? ciudad.imperioId : "";
  const imperioRef = partidaRef.collection("imperios").doc(imperioId);
  const imperioSnap = await imperioRef.get();

  if (!imperioSnap.exists) {
    throw new HttpsError("not-found", "El imperio no existe.");
  }

  const imperio = imperioSnap.data() ?? {};

  if (imperio.userId !== userId) {
    throw new HttpsError(
      "permission-denied",
      "No puedes consultar tropas para este imperio."
    );
  }

  const razaId = typeof imperio.razaId === "string" ? imperio.razaId : "";
  const tropasSnap = await db
    .collection("razas")
    .doc(razaId)
    .collection("tropas")
    .where("activo", "==", true)
    .get();

  const disponibles: Record<string, unknown>[] = [];

  tropasSnap.docs.forEach((doc) => {
      const tropa = doc.data();
      const desbloqueo =
        typeof tropa.desbloqueo === "object" &&
        tropa.desbloqueo !== null &&
        !Array.isArray(tropa.desbloqueo)
          ? (tropa.desbloqueo as Record<string, unknown>)
          : {};
      const cumplePoblacion =
        numero(ciudad.poblacion) >= numero(desbloqueo.poblacionMinima);
      const cumpleDia =
        numero(partida.diaActual) >= numero(desbloqueo.diaMinimo);
      const esPorFama = desbloqueo.porFama === true;

      if (!cumplePoblacion || !cumpleDia || esPorFama) return;

      disponibles.push({
        id: doc.id,
        ...tropa
      });
    });

  disponibles.sort((a, b) => numero(a.nivel) - numero(b.nivel));

  return disponibles;
});
