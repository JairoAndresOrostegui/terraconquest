import * as admin from "firebase-admin";
import type { DocumentReference, Transaction } from "firebase-admin/firestore";

const clases = ["guerrero", "ladron", "mago", "sacerdote"];

function random(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function calcularNivelPorDia(dia: number): number {
  if (dia < 5) return random(1, 2);
  if (dia < 10) return random(2, 4);
  if (dia < 20) return random(3, 6);
  if (dia < 40) return random(5, 8);
  return random(7, 12);
}

function statsBasePorClase(clase: string, nivel: number) {
  const base = nivel * 10;

  switch (clase) {
    case "guerrero":
      return {
        ataque: base * 1.2,
        defensa: base * 1.3,
        danio: base,
        vida: base * 3,
        velocidad: base * 0.6,
        moral: base * 1.1
      };
    case "ladron":
      return {
        ataque: base * 1.4,
        defensa: base * 0.8,
        danio: base * 1.2,
        vida: base * 1.8,
        velocidad: base * 1.5,
        moral: base
      };
    case "mago":
      return {
        ataque: base * 1.6,
        defensa: base * 0.7,
        danio: base * 1.5,
        vida: base * 1.5,
        velocidad: base,
        moral: base * 1.2
      };
    case "sacerdote":
      return {
        ataque: base * 0.8,
        defensa: base * 1.1,
        danio: base * 0.7,
        vida: base * 2,
        velocidad: base,
        moral: base * 1.5
      };
    default:
      return {
        ataque: base,
        defensa: base,
        danio: base,
        vida: base * 2,
        velocidad: base,
        moral: base
      };
  }
}

function calcularPrecio(nivel: number): number {
  return Math.floor(nivel * nivel * 800 + random(0, 500));
}

export async function generarHeroesMercado(params: {
  tx: Transaction;
  partidaRef: DocumentReference;
  dia: number;
}) {
  const { tx, partidaRef, dia } = params;
  const mercadoRef = partidaRef.collection("heroesMercado");
  const existentes = await tx.get(mercadoRef);

  existentes.docs.forEach((doc) => {
    const data = doc.data();

    if (data.disponible === true) {
      tx.delete(doc.ref);
    }
  });

  const cantidadHeroes = 6;

  for (let i = 0; i < cantidadHeroes; i++) {
    const clase = clases[random(0, clases.length - 1)];
    const nivel = calcularNivelPorDia(dia);
    const stats = statsBasePorClase(clase, nivel);

    tx.set(mercadoRef.doc(), {
      clase,
      nivel,
      precioOro: calcularPrecio(nivel),
      ataque: Math.floor(stats.ataque),
      defensa: Math.floor(stats.defensa),
      danio: Math.floor(stats.danio),
      vida: Math.floor(stats.vida),
      velocidad: Math.floor(stats.velocidad),
      moral: Math.floor(stats.moral),
      puntosDesarrollo: Math.floor(nivel / 2),
      imagenUrl: "",
      disponible: true,
      generadoDia: dia,
      creadoEn: admin.firestore.FieldValue.serverTimestamp()
    });
  }
}
