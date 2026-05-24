import * as admin from "firebase-admin";

type EventoDinamico = {
  tipo: string;
  titulo: string;
  descripcion: string;
  efectos: {
    poblacionDelta?: number;
    felicidadDelta?: number;
    higieneDelta?: number;
    corrupcionDelta?: number;
  };
};

function numero(valor: unknown): number {
  if (typeof valor === "number" && Number.isFinite(valor)) return valor;
  return Number.parseInt(String(valor ?? "0"), 10) || 0;
}

function clamp(valor: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, valor));
}

export function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

export function evaluarEventoCiudad(
  ciudad: Record<string, unknown>
): EventoDinamico[] {
  const felicidad = numero(ciudad.felicidad) || 100;
  const corrupcion = numero(ciudad.corrupcion);
  const higiene = numero(ciudad.higiene) || 100;
  const desempleo = numero(ciudad.desempleo);
  const poblacion = numero(ciudad.poblacion);
  const eventos: EventoDinamico[] = [];

  if (felicidad < 30 && randomInt(1, 100) <= 20) {
    eventos.push({
      tipo: "rebelion",
      titulo: "Rebelión en la ciudad",
      descripcion:
        "La baja felicidad provocó disturbios y pérdida de población.",
      efectos: {
        poblacionDelta: -Math.floor(poblacion * 0.05),
        felicidadDelta: -5
      }
    });
  }

  if (higiene < 30 && randomInt(1, 100) <= 18) {
    eventos.push({
      tipo: "plaga",
      titulo: "Plaga",
      descripcion: "La mala higiene provocó una plaga en la ciudad.",
      efectos: {
        poblacionDelta: -Math.floor(poblacion * 0.04),
        higieneDelta: -5
      }
    });
  }

  if (corrupcion > 70 && randomInt(1, 100) <= 20) {
    eventos.push({
      tipo: "corrupcion",
      titulo: "Corrupción administrativa",
      descripcion:
        "La corrupción redujo la producción y afectó el orden interno.",
      efectos: {
        felicidadDelta: -4,
        corrupcionDelta: 5
      }
    });
  }

  if (desempleo > 60 && randomInt(1, 100) <= 15) {
    eventos.push({
      tipo: "delincuencia",
      titulo: "Aumento de delincuencia",
      descripcion: "El alto desempleo aumentó el desorden en la ciudad.",
      efectos: {
        felicidadDelta: -3,
        corrupcionDelta: 3
      }
    });
  }

  if (felicidad > 85 && higiene > 80 && randomInt(1, 100) <= 10) {
    eventos.push({
      tipo: "prosperidad",
      titulo: "Prosperidad",
      descripcion:
        "La ciudad vivió un periodo de prosperidad y crecimiento.",
      efectos: {
        poblacionDelta: Math.floor(poblacion * 0.03),
        felicidadDelta: 3
      }
    });
  }

  return eventos;
}

export function aplicarEventoCiudad(
  ciudad: Record<string, unknown>,
  evento: EventoDinamico
) {
  const efectos = evento.efectos;

  return {
    poblacion: Math.max(0, numero(ciudad.poblacion) + numero(efectos.poblacionDelta)),
    felicidad: clamp(
      numero(ciudad.felicidad) + numero(efectos.felicidadDelta),
      0,
      100
    ),
    higiene: clamp(numero(ciudad.higiene) + numero(efectos.higieneDelta), 0, 100),
    corrupcion: clamp(
      numero(ciudad.corrupcion) + numero(efectos.corrupcionDelta),
      0,
      100
    )
  };
}

export function eventoFirestore(params: {
  evento: EventoDinamico;
  partidaId: string;
  ciudadId: string;
  imperioId: string;
  clanId?: string | null;
  dia: number;
}) {
  return {
    tipo: params.evento.tipo,
    titulo: params.evento.titulo,
    descripcion: params.evento.descripcion,
    partidaId: params.partidaId,
    ciudadId: params.ciudadId,
    imperioId: params.imperioId,
    clanId: params.clanId ?? null,
    visibleGlobal: false,
    visibleClanId: params.clanId ?? null,
    dia: params.dia,
    creadoEn: admin.firestore.FieldValue.serverTimestamp()
  };
}
