import * as admin from "firebase-admin";
import {
  calcularCorrupcion,
  calcularDesempleo,
  calcularFelicidad,
  calcularHigiene
} from "./calculoSocial";
import {
  aplicarEventoCiudad,
  evaluarEventoCiudad,
  eventoFirestore
} from "./eventosDinamicos";
import { generarHeroesMercado } from "./generarHeroesMercado";

const recursosKeys = [
  "oro",
  "alimentos",
  "agua",
  "madera",
  "piedra",
  "hierro",
  "herramientas",
  "armas",
  "bloques",
  "tablas",
  "mithril",
  "cristal",
  "plata",
  "reliquias",
  "gemas",
  "joyas",
  "mana",
  "karma"
];

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

function sumarRecursos(
  actuales: Record<string, number>,
  produccion: Record<string, number>
): Record<string, number> {
  const resultado: Record<string, number> = {};

  for (const key of recursosKeys) {
    resultado[key] = numero(actuales[key]) + numero(produccion[key]);
  }

  return resultado;
}

function calcularValorImperio(imperio: Record<string, unknown>): number {
  const poblacion = numero(imperio.totalPoblacion);
  const edificios = numero(imperio.totalEdificios);
  const tropas = numero(imperio.totalTropas);
  const recursos = mapaNumerico(imperio.recursos);
  let valorRecursos = 0;

  for (const key of recursosKeys) {
    valorRecursos += Math.floor(numero(recursos[key]) / 1000);
  }

  return Math.floor(poblacion * 0.2 + edificios * 15 + tropas * 0.8 + valorRecursos);
}

function bajarIndiceBelico(valor: number): number {
  return Math.max(0, valor - 5);
}

export async function procesarPasoDiaPartida(partidaId: string) {
  const db = admin.firestore();
  const partidaRef = db.collection("partidas").doc(partidaId);
  const bloqueoRef = partidaRef.collection("control").doc("pasoDia");
  const logRef = partidaRef.collection("pasosDiaLogs").doc();
  let nuevoDia = 0;

  await db.runTransaction(async (tx) => {
    const [partidaSnap, bloqueoSnap] = await Promise.all([
      tx.get(partidaRef),
      tx.get(bloqueoRef)
    ]);

    if (!partidaSnap.exists) {
      throw new Error("La partida no existe.");
    }

    const partida = partidaSnap.data() ?? {};

    if (partida.estado !== "activa") {
      throw new Error("La partida no esta activa.");
    }

    nuevoDia = numero(partida.diaActual) + 1;

    const bloqueo = bloqueoSnap.exists ? bloqueoSnap.data() ?? {} : {};

    if (bloqueo.estado === "ejecutando") {
      throw new Error("El paso de dia ya se esta ejecutando.");
    }

    if (numero(bloqueo.ultimoDiaProcesado) === nuevoDia) {
      throw new Error("Este dia ya fue procesado.");
    }

    tx.set(
      bloqueoRef,
      {
        estado: "ejecutando",
        diaEnProceso: nuevoDia,
        ultimoDiaProcesado: numero(bloqueo.ultimoDiaProcesado),
        inicioProceso: admin.firestore.FieldValue.serverTimestamp(),
        error: null,
        actualizadoEn: admin.firestore.FieldValue.serverTimestamp()
      },
      { merge: true }
    );

    tx.set(logRef, {
      diaProcesado: nuevoDia,
      inicioProceso: admin.firestore.FieldValue.serverTimestamp(),
      finProceso: null,
      estado: "ejecutando",
      imperiosProcesados: 0,
      ciudadesProcesadas: 0,
      heroesProcesados: 0,
      clanesProcesados: 0,
      error: null
    });
  });

  try {
    const ciudadesSnap = await partidaRef
      .collection("ciudades")
      .where("estado", "==", "activa")
      .get();

    let batch = db.batch();
    let operaciones = 0;
    const poblacionPorImperio: Record<string, number> = {};
    const edificiosPorImperio: Record<string, number> = {};

    for (const ciudadDoc of ciudadesSnap.docs) {
      const ciudad = ciudadDoc.data();
      const imperioId = typeof ciudad.imperioId === "string" ? ciudad.imperioId : "";
      if (imperioId.length === 0) continue;

      const poblacionActual = numero(ciudad.poblacion);
      const crecimiento = numero(ciudad.crecimientoPoblacionDia);
      const nuevaPoblacion = poblacionActual + crecimiento;
      const ciudadSimulada = {
        ...ciudad,
        poblacion: nuevaPoblacion
      };
      const nuevaCorrupcion = calcularCorrupcion(ciudadSimulada);
      const nuevaHigiene = calcularHigiene(ciudadSimulada);
      const nuevoDesempleo = calcularDesempleo(ciudadSimulada);
      const ciudadConSocial = {
        ...ciudadSimulada,
        corrupcion: nuevaCorrupcion,
        higiene: nuevaHigiene,
        desempleo: nuevoDesempleo
      };
      const nuevaFelicidad = calcularFelicidad(ciudadConSocial);
      let ciudadFinal: Record<string, unknown> = {
        ...ciudadConSocial,
        felicidad: nuevaFelicidad
      };
      const eventosCiudad = evaluarEventoCiudad(ciudadFinal);

      for (const evento of eventosCiudad) {
        ciudadFinal = {
          ...ciudadFinal,
          ...aplicarEventoCiudad(ciudadFinal, evento)
        };

        batch.set(
          partidaRef.collection("eventos").doc(),
          eventoFirestore({
            evento,
            partidaId,
            ciudadId: ciudadDoc.id,
            imperioId,
            clanId: typeof ciudad.clanId === "string" ? ciudad.clanId : null,
            dia: nuevoDia
          })
        );

        operaciones++;
      }

      poblacionPorImperio[imperioId] =
        (poblacionPorImperio[imperioId] ?? 0) + numero(ciudadFinal.poblacion);
      edificiosPorImperio[imperioId] =
        (edificiosPorImperio[imperioId] ?? 0) + numero(ciudad.totalEdificios);

      batch.update(ciudadDoc.ref, {
        poblacion: numero(ciudadFinal.poblacion),
        corrupcion: numero(ciudadFinal.corrupcion),
        higiene: numero(ciudadFinal.higiene),
        desempleo: numero(ciudadFinal.desempleo),
        felicidad: numero(ciudadFinal.felicidad),
        actualizadoEn: admin.firestore.FieldValue.serverTimestamp()
      });

      operaciones++;

      if (operaciones >= 450) {
        await batch.commit();
        batch = db.batch();
        operaciones = 0;
      }
    }

    if (operaciones > 0) {
      await batch.commit();
    }

    const imperiosSnap = await partidaRef
      .collection("imperios")
      .where("estado", "==", "activo")
      .get();

    batch = db.batch();
    operaciones = 0;

    const rankingTemporal: {
      ref: FirebaseFirestore.DocumentReference;
      imperioId: string;
      nombre: string;
      razaId: string;
      clanId: string | null;
      valor: number;
      rankingAnterior: number;
      ciudades: number;
      heroes: number;
    }[] = [];

    for (const imperioDoc of imperiosSnap.docs) {
      const imperio = imperioDoc.data();
      const nuevosRecursos = sumarRecursos(
        mapaNumerico(imperio.recursos),
        mapaNumerico(imperio.produccionDiaria)
      );
      const turnosGeneradosDia = numero(imperio.turnosGeneradosDia) || 100;
      const nuevosTurnos = numero(imperio.turnos) + turnosGeneradosDia;
      const totalPoblacion =
        poblacionPorImperio[imperioDoc.id] ?? numero(imperio.totalPoblacion);
      const totalEdificios =
        edificiosPorImperio[imperioDoc.id] ?? numero(imperio.totalEdificios);
      const imperioActualizado = {
        ...imperio,
        recursos: nuevosRecursos,
        totalPoblacion,
        totalEdificios
      };
      const nuevoValor = calcularValorImperio(imperioActualizado);
      const rankingAnterior = numero(imperio.ranking);

      batch.update(imperioDoc.ref, {
        recursos: nuevosRecursos,
        turnos: nuevosTurnos,
        indiceBelico: bajarIndiceBelico(numero(imperio.indiceBelico)),
        valor: nuevoValor,
        valorSinVictoriasHeroes: nuevoValor,
        totalPoblacion,
        totalEdificios,
        rankingAnterior,
        actualizadoEn: admin.firestore.FieldValue.serverTimestamp()
      });

      rankingTemporal.push({
        ref: imperioDoc.ref,
        imperioId: imperioDoc.id,
        nombre: typeof imperio.nombre === "string" ? imperio.nombre : "",
        razaId: typeof imperio.razaId === "string" ? imperio.razaId : "",
        clanId: typeof imperio.clanId === "string" ? imperio.clanId : null,
        valor: nuevoValor,
        rankingAnterior,
        ciudades: numero(imperio.totalCiudades),
        heroes: numero(imperio.totalHeroes)
      });

      operaciones++;

      if (operaciones >= 450) {
        await batch.commit();
        batch = db.batch();
        operaciones = 0;
      }
    }

    if (operaciones > 0) {
      await batch.commit();
    }

    rankingTemporal.sort((a, b) => b.valor - a.valor);

    batch = db.batch();
    operaciones = 0;

    for (let i = 0; i < rankingTemporal.length; i++) {
      const item = rankingTemporal[i];
      const ranking = i + 1;

      batch.update(item.ref, {
        ranking,
        actualizadoEn: admin.firestore.FieldValue.serverTimestamp()
      });

      batch.set(partidaRef.collection("rankingsImperios").doc(item.imperioId), {
        imperioId: item.imperioId,
        nombreImperio: item.nombre,
        razaId: item.razaId,
        clanId: item.clanId,
        tagClan: null,
        valor: item.valor,
        ranking,
        rankingAnterior: item.rankingAnterior,
        ciudades: item.ciudades,
        heroes: item.heroes,
        dia: nuevoDia,
        actualizadoEn: admin.firestore.FieldValue.serverTimestamp()
      });

      operaciones += 2;

      if (operaciones >= 450) {
        await batch.commit();
        batch = db.batch();
        operaciones = 0;
      }
    }

    if (operaciones > 0) {
      await batch.commit();
    }

    await db.runTransaction(async (tx) => {
      await generarHeroesMercado({
        tx,
        partidaRef,
        dia: nuevoDia
      });

      tx.update(partidaRef, {
        diaActual: nuevoDia,
        ultimoPasoDia: admin.firestore.FieldValue.serverTimestamp(),
        actualizadoEn: admin.firestore.FieldValue.serverTimestamp()
      });

      tx.set(partidaRef.collection("eventos").doc(), {
        tipo: "sistema",
        titulo: "Nuevo mercado de héroes",
        descripcion: "Nuevos héroes están disponibles en el mercado.",
        partidaId,
        ciudadId: null,
        imperioId: null,
        clanId: null,
        visibleGlobal: true,
        visibleClanId: null,
        dia: nuevoDia,
        creadoEn: admin.firestore.FieldValue.serverTimestamp()
      });

      tx.set(
        bloqueoRef,
        {
          estado: "completado",
          diaEnProceso: null,
          ultimoDiaProcesado: nuevoDia,
          finProceso: admin.firestore.FieldValue.serverTimestamp(),
          error: null,
          actualizadoEn: admin.firestore.FieldValue.serverTimestamp()
        },
        { merge: true }
      );
    });

    await logRef.update({
      finProceso: admin.firestore.FieldValue.serverTimestamp(),
      estado: "completado",
      imperiosProcesados: imperiosSnap.size,
      ciudadesProcesadas: ciudadesSnap.size,
      heroesProcesados: 0,
      clanesProcesados: 0
    });

    return {
      ok: true,
      partidaId,
      diaProcesado: nuevoDia,
      imperiosProcesados: imperiosSnap.size,
      ciudadesProcesadas: ciudadesSnap.size
    };
  } catch (error) {
    await logRef.update({
      finProceso: admin.firestore.FieldValue.serverTimestamp(),
      estado: "error",
      error: error instanceof Error ? error.message : "Error desconocido"
    });

    await bloqueoRef.set(
      {
        estado: "error",
        diaEnProceso: nuevoDia || null,
        error: error instanceof Error ? error.message : "Error desconocido",
        finProceso: admin.firestore.FieldValue.serverTimestamp(),
        actualizadoEn: admin.firestore.FieldValue.serverTimestamp()
      },
      { merge: true }
    );

    throw error;
  }
}
