import * as admin from "firebase-admin";
import type { DocumentReference, Transaction } from "firebase-admin/firestore";

export const RECURSOS_BASE: Record<string, number> = {
  oro: 0,
  alimentos: 0,
  agua: 0,
  madera: 0,
  piedra: 0,
  hierro: 0,
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

type CiudadActualizada = {
  ciudadId: string;
  produccionDiaria: Record<string, number>;
  poblacion: number;
  totalEdificios: number;
};

export function numero(valor: unknown): number {
  if (typeof valor === "number" && Number.isFinite(valor)) return valor;
  return Number.parseInt(String(valor ?? "0"), 10) || 0;
}

function factorImpuestos(impuestosPct: number): number {
  if (impuestosPct <= 0) return 0.8;
  if (impuestosPct <= 10) return 1.0;
  if (impuestosPct <= 20) return 1.15;
  if (impuestosPct <= 30) return 1.30;
  if (impuestosPct <= 40) return 1.45;
  return 1.6;
}

function penalizacionCrecimientoPorImpuestos(impuestosPct: number): number {
  if (impuestosPct <= 10) return 0;
  if (impuestosPct <= 20) return -5;
  if (impuestosPct <= 30) return -10;
  if (impuestosPct <= 40) return -20;
  return -30;
}

export function mapaNumerico(valor: unknown): Record<string, number> {
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

export function aplicarBono(valor: number, porcentaje: number): number {
  return Math.floor(valor * (1 + porcentaje / 100));
}

export function bonoTerreno(
  terreno: Record<string, unknown>,
  recurso: string
): number {
  const bonos = terreno.bonos;

  if (typeof bonos !== "object" || bonos === null || Array.isArray(bonos)) {
    return 0;
  }

  return numero((bonos as Record<string, unknown>)[`${recurso}Pct`]);
}

export function bonoRegion(
  region: Record<string, unknown>,
  recurso: string
): number {
  const bonos = region.bonos;

  if (typeof bonos !== "object" || bonos === null || Array.isArray(bonos)) {
    return 0;
  }

  const bonosRegion = bonos as Record<string, unknown>;
  return (
    numero(bonosRegion[`${recurso}Pct`]) +
    numero(bonosRegion.produccionPct)
  );
}

function valorPorRuta(
  data: Record<string, unknown>,
  seccion: string,
  campo: string
): number {
  const bloque = data[seccion];

  if (typeof bloque !== "object" || bloque === null || Array.isArray(bloque)) {
    return 0;
  }

  return numero((bloque as Record<string, unknown>)[campo]);
}

export function bonoRazaProduccion(raza: Record<string, unknown>): number {
  return (
    valorPorRuta(raza, "bonos", "produccionPct") -
    valorPorRuta(raza, "penalizaciones", "produccionPct")
  );
}

export function bonoRazaCrecimiento(raza: Record<string, unknown>): number {
  return (
    valorPorRuta(raza, "bonos", "crecimientoPct") -
    valorPorRuta(raza, "penalizaciones", "crecimientoPct")
  );
}

export function calcularProduccionCiudad(params: {
  ciudad: Record<string, unknown>;
  edificios: Record<string, number>;
  terreno: Record<string, unknown>;
  raza: Record<string, unknown>;
  region?: Record<string, unknown>;
}) {
  const { ciudad, edificios, terreno, raza, region = {} } = params;
  const poblacion = numero(ciudad.poblacion);
  const produccion = { ...RECURSOS_BASE };

  produccion.oro += numero(edificios.minaOro) * 120;
  produccion.alimentos += numero(edificios.cultivos) * 150;
  produccion.agua += numero(edificios.pozos) * 150;
  produccion.madera += numero(edificios.aserradero) * 130;
  produccion.piedra += numero(edificios.cantera) * 120;
  produccion.hierro += numero(edificios.minaHierro) * 90;
  produccion.herramientas += numero(edificios.taller) * 45;
  produccion.armas += numero(edificios.forjaHierro) * 35;
  produccion.tablas += numero(edificios.carpinteria) * 50;
  produccion.bloques += numero(edificios.minaPiedra) * 40;
  produccion.mithril += numero(edificios.minaMithril) * 20;
  produccion.cristal += numero(edificios.camaraCristal) * 20;
  produccion.plata += numero(edificios.minaPlata) * 40;
  produccion.joyas += numero(edificios.joyeria) * 15;
  produccion.mana += numero(edificios.torreMagica) * 20;
  produccion.karma += numero(edificios.templo) * 20;
  const impuestosPct = numero(ciudad.impuestosPct) || 10;
  produccion.oro += Math.floor(
    poblacion * 0.05 * factorImpuestos(impuestosPct)
  );

  for (const recurso of Object.keys(produccion)) {
    const bonoTotal =
      bonoTerreno(terreno, recurso) +
      bonoRegion(region, recurso) +
      bonoRazaProduccion(raza);
    const corrupcion = numero(ciudad.corrupcion);
    const valorConBonos = aplicarBono(produccion[recurso], bonoTotal);

    produccion[recurso] = Math.max(
      0,
      Math.floor(valorConBonos * (1 - corrupcion / 150))
    );
  }

  const consumoDiario = {
    alimentos: Math.floor(poblacion * 0.02),
    agua: Math.floor(poblacion * 0.02)
  };

  const higiene = numero(ciudad.higiene) || 100;
  const felicidad = numero(ciudad.felicidad) || 100;
  const desempleo = numero(ciudad.desempleo);
  const crecimientoBase = Math.floor(
    (poblacion * 0.01) *
      (higiene / 100) *
      (felicidad / 100) *
      (1 - desempleo / 100)
  );
  const crecimientoConBonos = aplicarBono(
    crecimientoBase,
    bonoTerreno(terreno, "crecimiento") +
      bonoRegion(region, "crecimiento") +
      bonoRazaCrecimiento(raza)
  );
  const crecimientoPoblacionDia = Math.max(
    0,
    aplicarBono(
      crecimientoConBonos,
      penalizacionCrecimientoPorImpuestos(impuestosPct)
    )
  );

  return {
    produccionDiaria: produccion,
    consumoDiario,
    crecimientoPoblacionDia
  };
}

export async function recalcularProduccionImperio(params: {
  tx: Transaction;
  partidaRef: DocumentReference;
  imperioRef: DocumentReference;
  imperioId: string;
  ciudadActualizada?: CiudadActualizada;
}) {
  const { tx, partidaRef, imperioRef, imperioId, ciudadActualizada } = params;
  const ciudadesSnap = await tx.get(
    partidaRef.collection("ciudades").where("imperioId", "==", imperioId)
  );
  const total = { ...RECURSOS_BASE };
  let totalPoblacion = 0;
  let totalEdificios = 0;
  let ciudadActualizadaIncluida = false;

  ciudadesSnap.docs.forEach((doc) => {
    const ciudad = doc.data();
    const usaCiudadActualizada = doc.id === ciudadActualizada?.ciudadId;
    ciudadActualizadaIncluida = ciudadActualizadaIncluida || usaCiudadActualizada;
    const produccion = usaCiudadActualizada
      ? ciudadActualizada.produccionDiaria
      : mapaNumerico(ciudad.produccionDiaria);

    Object.keys(total).forEach((recurso) => {
      total[recurso] += numero(produccion[recurso]);
    });

    totalPoblacion += usaCiudadActualizada
      ? ciudadActualizada.poblacion
      : numero(ciudad.poblacion);
    totalEdificios += usaCiudadActualizada
      ? ciudadActualizada.totalEdificios
      : numero(ciudad.totalEdificios);
  });

  if (ciudadActualizada && !ciudadActualizadaIncluida) {
    Object.keys(total).forEach((recurso) => {
      total[recurso] += numero(ciudadActualizada.produccionDiaria[recurso]);
    });

    totalPoblacion += ciudadActualizada.poblacion;
    totalEdificios += ciudadActualizada.totalEdificios;
  }

  const totalCiudades =
    ciudadesSnap.size + (ciudadActualizada && !ciudadActualizadaIncluida ? 1 : 0);

  tx.update(imperioRef, {
    produccionDiaria: total,
    totalPoblacion,
    totalEdificios,
    totalCiudades,
    actualizadoEn: admin.firestore.FieldValue.serverTimestamp()
  });

  return {
    produccionDiaria: total,
    totalPoblacion,
    totalEdificios,
    totalCiudades
  };
}
