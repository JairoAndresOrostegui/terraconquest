import * as admin from "firebase-admin";
import { logger } from "firebase-functions";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { procesarPasoDiaPartida } from "./core/procesarPasoDia";

export const pasarDiaAutomatico = onSchedule(
  {
    schedule: "0 0 * * *",
    timeZone: "America/Bogota",
    region: "us-central1",
    memory: "1GiB",
    timeoutSeconds: 540
  },
  async () => {
    const db = admin.firestore();

    logger.info("Iniciando paso diario automático.");

    const partidasSnap = await db
      .collection("partidas")
      .where("estado", "==", "activa")
      .get();
    const resultados = [];

    for (const partidaDoc of partidasSnap.docs) {
      try {
        const resultado = await procesarPasoDiaPartida(partidaDoc.id);
        resultados.push(resultado);

        logger.info("Paso diario completado.", {
          partidaId: partidaDoc.id,
          resultado
        });
      } catch (error) {
        logger.error("Error procesando paso diario.", {
          partidaId: partidaDoc.id,
          error: error instanceof Error ? error.message : error
        });
      }
    }

    logger.info("Paso diario automático finalizado.", {
      totalPartidas: partidasSnap.size,
      resultados
    });
  }
);
