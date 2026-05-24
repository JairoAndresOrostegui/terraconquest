function numero(valor: unknown): number {
  if (typeof valor === "number" && Number.isFinite(valor)) return valor;
  return Number.parseInt(String(valor ?? "0"), 10) || 0;
}

export function clamp(valor: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, valor));
}

export function calcularFelicidad(ciudad: Record<string, unknown>): number {
  const impuestos = numero(ciudad.impuestosPct) || 10;
  const higiene = numero(ciudad.higiene) || 100;
  const corrupcion = numero(ciudad.corrupcion);
  let felicidad = 100;

  felicidad -= impuestos * 0.8;
  felicidad += (higiene - 50) * 0.3;
  felicidad -= corrupcion * 0.5;

  return clamp(Math.floor(felicidad), 0, 100);
}

export function calcularCorrupcion(ciudad: Record<string, unknown>): number {
  const poblacion = numero(ciudad.poblacion);
  const impuestos = numero(ciudad.impuestosPct) || 10;
  const edificios = numero(ciudad.totalEdificios) || 1;
  let corrupcion = 0;

  corrupcion += Math.floor(poblacion / 1000) * 2;
  corrupcion += Math.floor(impuestos / 10) * 3;
  corrupcion -= Math.floor(edificios / 10);

  return clamp(corrupcion, 0, 100);
}

export function calcularHigiene(ciudad: Record<string, unknown>): number {
  const poblacion = numero(ciudad.poblacion);
  const edificios = numero(ciudad.totalEdificios) || 1;
  let higiene = 100;

  higiene -= Math.floor(poblacion / 500);
  higiene += Math.floor(edificios / 5);

  return clamp(higiene, 0, 100);
}

export function calcularDesempleo(ciudad: Record<string, unknown>): number {
  const poblacion = numero(ciudad.poblacion);
  const edificios = numero(ciudad.totalEdificios) || 1;
  const capacidadTrabajo = edificios * 80;

  if (poblacion <= capacidadTrabajo) return 0;

  const desempleo = ((poblacion - capacidadTrabajo) / poblacion) * 100;

  return clamp(Math.floor(desempleo), 0, 100);
}
