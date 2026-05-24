import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

type DesbloquearPasoDiaData = {
  partidaId?: unknown;
};

function obtenerPartidaId(data: DesbloquearPasoDiaData): string {
  const valor = data.partidaId;
  if (typeof valor !== "string" || valor.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Falta partidaId.");
  }
  return valor.trim();
}

export const desbloquearPasoDia = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const db = admin.firestore();
  const userId = request.auth.uid;
  const partidaId = obtenerPartidaId(request.data as DesbloquearPasoDiaData);
  const userSnap = await db.collection("usuarios").doc(userId).get();

  if (!userSnap.exists || userSnap.data()?.rol !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Solo un administrador puede desbloquear el paso de día."
    );
  }

  const partidaRef = db.collection("partidas").doc(partidaId);
  const controlRef = partidaRef.collection("control").doc("pasoDia");
  const [partidaSnap, controlSnap] = await Promise.all([
    partidaRef.get(),
    controlRef.get()
  ]);

  if (!partidaSnap.exists) {
    throw new HttpsError("not-found", "La partida no existe.");
  }

  const partida = partidaSnap.data() ?? {};
  const diaActual =
    typeof partida.diaActual === "number" && Number.isFinite(partida.diaActual)
      ? partida.diaActual
      : 0;

  if (!controlSnap.exists) {
    await controlRef.set({
      estado: "completado",
      diaEnProceso: null,
      ultimoDiaProcesado: diaActual,
      error: null,
      actualizadoEn: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      ok: true,
      mensaje: "Control de paso de día creado correctamente."
    };
  }

  const control = controlSnap.data() ?? {};

  if (control.estado === "completado") {
    return {
      ok: true,
      mensaje: "El paso de día no estaba bloqueado."
    };
  }

  await controlRef.set(
    {
      estado: "completado",
      diaEnProceso: null,
      error: null,
      desbloqueadoManual: true,
      desbloqueadoPor: userId,
      desbloqueadoEn: admin.firestore.FieldValue.serverTimestamp(),
      actualizadoEn: admin.firestore.FieldValue.serverTimestamp()
    },
    { merge: true }
  );

  await partidaRef.collection("eventos").doc().set({
    tipo: "sistema",
    titulo: "Paso de día desbloqueado",
    descripcion:
      "Un administrador desbloqueó manualmente el control del paso de día.",
    imperioId: null,
    clanId: null,
    visibleGlobal: false,
    visibleClanId: null,
    dia: diaActual,
    creadoEn: admin.firestore.FieldValue.serverTimestamp()
  });

  return {
    ok: true,
    mensaje: "Paso de día desbloqueado correctamente."
  };
});
