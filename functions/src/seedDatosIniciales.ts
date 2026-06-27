import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

export const seedDatosIniciales = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const db = admin.firestore();
  const userId = request.auth.uid;
  const userSnap = await db.collection("usuarios").doc(userId).get();

  if (!userSnap.exists || userSnap.data()?.rol !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Solo un administrador puede crear datos iniciales."
    );
  }

  const batch = db.batch();
  const ahora = admin.firestore.FieldValue.serverTimestamp();
  const razas = [
    {
      id: "humanos",
      codigo: "humanos",
      nombre: "Humanos",
      descripcion: "Raza equilibrada, adaptable y estable.",
      imagenUrl: "",
      activo: true,
      bonos: {
        produccionPct: 5,
        crecimientoPct: 5,
        ataquePct: 0,
        defensaPct: 0,
        comercioPct: 5,
        magiaPct: 0
      },
      penalizaciones: {
        produccionPct: 0,
        crecimientoPct: 0,
        ataquePct: 0,
        defensaPct: 0
      },
      creadoEn: ahora,
      actualizadoEn: ahora
    },
    {
      id: "no_muertos",
      codigo: "no_muertos",
      nombre: "No Muertos",
      descripcion: "Raza oscura con buen potencial militar y mágico.",
      imagenUrl: "",
      activo: true,
      bonos: {
        produccionPct: 0,
        crecimientoPct: -5,
        ataquePct: 8,
        defensaPct: 0,
        comercioPct: -5,
        magiaPct: 10
      },
      penalizaciones: {
        produccionPct: 0,
        crecimientoPct: 5,
        ataquePct: 0,
        defensaPct: 0
      },
      creadoEn: ahora,
      actualizadoEn: ahora
    },
    {
      id: "enanos",
      codigo: "enanos",
      nombre: "Enanos",
      descripcion: "Raza defensiva con alta producción minera.",
      imagenUrl: "",
      activo: true,
      bonos: {
        produccionPct: 8,
        crecimientoPct: -3,
        ataquePct: 0,
        defensaPct: 10,
        comercioPct: 0,
        magiaPct: -5
      },
      penalizaciones: {
        produccionPct: 0,
        crecimientoPct: 3,
        ataquePct: 0,
        defensaPct: 0
      },
      creadoEn: ahora,
      actualizadoEn: ahora
    }
  ];

  for (const raza of razas) {
    batch.set(db.collection("razas").doc(raza.id), raza, { merge: true });
  }

  const tropas = [
    {
      id: "soldado_n1",
      razaId: "humanos",
      nivel: 1,
      nombre: "Soldado",
      descripcion: "Infanteria humana basica.",
      ataque: 8,
      defensa: 7,
      danio: 5,
      vida: 10,
      velocidad: 5,
      moral: 8,
      tipoAtaque: "fisico",
      tipoDefensa: "armadura",
      tipoMagia: "ninguno",
      habilidades: [],
      costeCompra: { oro: 80, alimentos: 10, armas: 1 },
      mantenimiento: { oro: 2, alimentos: 1 },
      desbloqueo: {
        poblacionMinima: 0,
        porFama: false,
        diaMinimo: 1,
        diaMaximo: null
      },
      activo: true
    },
    {
      id: "arquero_n2",
      razaId: "humanos",
      nivel: 2,
      nombre: "Arquero",
      descripcion: "Unidad humana de ataque a distancia.",
      ataque: 12,
      defensa: 6,
      danio: 8,
      vida: 9,
      velocidad: 6,
      moral: 8,
      tipoAtaque: "distancia",
      tipoDefensa: "ligera",
      tipoMagia: "ninguno",
      habilidades: ["disparo"],
      costeCompra: { oro: 130, alimentos: 15, armas: 2 },
      mantenimiento: { oro: 3, alimentos: 1 },
      desbloqueo: {
        poblacionMinima: 5000,
        porFama: false,
        diaMinimo: 1,
        diaMaximo: null
      },
      activo: true
    },
    {
      id: "caballero_n3",
      razaId: "humanos",
      nivel: 3,
      nombre: "Caballero",
      descripcion: "Caballeria humana de choque.",
      ataque: 18,
      defensa: 14,
      danio: 12,
      vida: 18,
      velocidad: 8,
      moral: 10,
      tipoAtaque: "fisico",
      tipoDefensa: "armadura",
      tipoMagia: "ninguno",
      habilidades: ["carga"],
      costeCompra: { oro: 260, alimentos: 30, armas: 4 },
      mantenimiento: { oro: 6, alimentos: 2 },
      desbloqueo: {
        poblacionMinima: 10000,
        porFama: false,
        diaMinimo: 1,
        diaMaximo: null
      },
      activo: true
    },
    {
      id: "esqueleto_n1",
      razaId: "no_muertos",
      nivel: 1,
      nombre: "Esqueleto",
      descripcion: "Unidad no-muerta basica.",
      ataque: 9,
      defensa: 5,
      danio: 6,
      vida: 8,
      velocidad: 5,
      moral: 10,
      tipoAtaque: "fisico",
      tipoDefensa: "osamenta",
      tipoMagia: "oscura",
      habilidades: ["sin_miedo"],
      costeCompra: { oro: 70, mana: 1 },
      mantenimiento: { mana: 1 },
      desbloqueo: {
        poblacionMinima: 0,
        porFama: false,
        diaMinimo: 1,
        diaMaximo: null
      },
      activo: true
    },
    {
      id: "zombi_n2",
      razaId: "no_muertos",
      nivel: 2,
      nombre: "Zombi",
      descripcion: "Unidad resistente de avance lento.",
      ataque: 11,
      defensa: 10,
      danio: 7,
      vida: 16,
      velocidad: 3,
      moral: 10,
      tipoAtaque: "fisico",
      tipoDefensa: "putrefaccion",
      tipoMagia: "oscura",
      habilidades: ["resistente"],
      costeCompra: { oro: 120, mana: 2 },
      mantenimiento: { mana: 1 },
      desbloqueo: {
        poblacionMinima: 5000,
        porFama: false,
        diaMinimo: 1,
        diaMaximo: null
      },
      activo: true
    },
    {
      id: "ghoul_n3",
      razaId: "no_muertos",
      nivel: 3,
      nombre: "Ghoul",
      descripcion: "Depredador no-muerto rapido.",
      ataque: 19,
      defensa: 9,
      danio: 13,
      vida: 14,
      velocidad: 9,
      moral: 10,
      tipoAtaque: "fisico",
      tipoDefensa: "ligera",
      tipoMagia: "oscura",
      habilidades: ["desgarrar"],
      costeCompra: { oro: 240, mana: 4 },
      mantenimiento: { oro: 2, mana: 2 },
      desbloqueo: {
        poblacionMinima: 10000,
        porFama: false,
        diaMinimo: 1,
        diaMaximo: null
      },
      activo: true
    },
    {
      id: "guerrero_enano_n1",
      razaId: "enanos",
      nivel: 1,
      nombre: "Guerrero enano",
      descripcion: "Infanteria enana robusta.",
      ataque: 7,
      defensa: 10,
      danio: 5,
      vida: 13,
      velocidad: 4,
      moral: 9,
      tipoAtaque: "fisico",
      tipoDefensa: "armadura",
      tipoMagia: "ninguno",
      habilidades: ["tenaz"],
      costeCompra: { oro: 90, alimentos: 10, armas: 1 },
      mantenimiento: { oro: 2, alimentos: 1 },
      desbloqueo: {
        poblacionMinima: 0,
        porFama: false,
        diaMinimo: 1,
        diaMaximo: null
      },
      activo: true
    },
    {
      id: "ballestero_n2",
      razaId: "enanos",
      nivel: 2,
      nombre: "Ballestero",
      descripcion: "Unidad enana de defensa a distancia.",
      ataque: 13,
      defensa: 9,
      danio: 9,
      vida: 11,
      velocidad: 4,
      moral: 9,
      tipoAtaque: "distancia",
      tipoDefensa: "armadura",
      tipoMagia: "ninguno",
      habilidades: ["perforante"],
      costeCompra: { oro: 150, alimentos: 12, armas: 2 },
      mantenimiento: { oro: 3, alimentos: 1 },
      desbloqueo: {
        poblacionMinima: 5000,
        porFama: false,
        diaMinimo: 1,
        diaMaximo: null
      },
      activo: true
    },
    {
      id: "guardian_n3",
      razaId: "enanos",
      nivel: 3,
      nombre: "Guardian",
      descripcion: "Defensor enano de alto aguante.",
      ataque: 15,
      defensa: 20,
      danio: 9,
      vida: 22,
      velocidad: 3,
      moral: 10,
      tipoAtaque: "fisico",
      tipoDefensa: "pesada",
      tipoMagia: "ninguno",
      habilidades: ["muro"],
      costeCompra: { oro: 280, alimentos: 20, armas: 4 },
      mantenimiento: { oro: 6, alimentos: 2 },
      desbloqueo: {
        poblacionMinima: 10000,
        porFama: false,
        diaMinimo: 1,
        diaMaximo: null
      },
      activo: true
    }
  ];

  for (const tropa of tropas) {
    const { id, ...data } = tropa;
    batch.set(
      db.collection("razas").doc(tropa.razaId).collection("tropas").doc(id),
      {
        codigo: id,
        ...data
      },
      { merge: true }
    );
  }

  batch.set(
    db.collection("catalogos").doc("desbloqueoTropas"),
    {
      habitantesPorNivel: 5000,
      activo: true,
      actualizadoEn: ahora
    },
    { merge: true }
  );

  batch.set(
    db.collection("catalogoCanjesFama").doc("tropas_altas_v1"),
    {
      tipo: "tropas",
      diaInicio: 10,
      diaFin: null,
      nivelesPermitidos: [10, 12, 14],
      costeFama: 100,
      cantidadNivelesAprox: 1000,
      activo: true,
      creadoEn: ahora,
      actualizadoEn: ahora
    },
    { merge: true }
  );

  const terrenos = [
    {
      id: "llanura",
      nombre: "Llanura",
      codigo: "LLA",
      descripcion: "Terreno equilibrado con buen crecimiento poblacional.",
      imagenUrl: "",
      activo: true,
      bonos: {
        ataquePct: 0,
        defensaPct: 0,
        crecimientoPct: 10,
        oroPct: 0,
        alimentosPct: 10,
        aguaPct: 0,
        maderaPct: 0,
        piedraPct: 0,
        hierroPct: 0,
        herramientasPct: 0,
        armasPct: 0,
        bloquesPct: 0,
        tablasPct: 0,
        mithrilPct: 0,
        cristalPct: 0,
        plataPct: 0,
        reliquiasPct: 0,
        gemasPct: 0,
        joyasPct: 0
      }
    },
    {
      id: "bosque",
      nombre: "Bosque",
      codigo: "BOS",
      descripcion: "Terreno con buena madera y defensa natural.",
      imagenUrl: "",
      activo: true,
      bonos: {
        ataquePct: 0,
        defensaPct: 8,
        crecimientoPct: 0,
        oroPct: 0,
        alimentosPct: 0,
        aguaPct: 0,
        maderaPct: 15,
        piedraPct: 0,
        hierroPct: 0,
        herramientasPct: 0,
        armasPct: 0,
        bloquesPct: 0,
        tablasPct: 10,
        mithrilPct: 0,
        cristalPct: 0,
        plataPct: 0,
        reliquiasPct: 0,
        gemasPct: 0,
        joyasPct: 0
      }
    },
    {
      id: "montana",
      nombre: "Montaña",
      codigo: "MON",
      descripcion: "Terreno defensivo con producción de piedra y hierro.",
      imagenUrl: "",
      activo: true,
      bonos: {
        ataquePct: 0,
        defensaPct: 15,
        crecimientoPct: -5,
        oroPct: 0,
        alimentosPct: 0,
        aguaPct: 0,
        maderaPct: -5,
        piedraPct: 15,
        hierroPct: 15,
        herramientasPct: 0,
        armasPct: 0,
        bloquesPct: 10,
        tablasPct: 0,
        mithrilPct: 5,
        cristalPct: 0,
        plataPct: 5,
        reliquiasPct: 0,
        gemasPct: 0,
        joyasPct: 0
      }
    },
    {
      id: "rio",
      nombre: "Río",
      codigo: "RIO",
      descripcion: "Terreno con alta disponibilidad de agua y alimentos.",
      imagenUrl: "",
      activo: true,
      bonos: {
        ataquePct: 0,
        defensaPct: 3,
        crecimientoPct: 8,
        oroPct: 0,
        alimentosPct: 8,
        aguaPct: 20,
        maderaPct: 0,
        piedraPct: 0,
        hierroPct: 0,
        herramientasPct: 0,
        armasPct: 0,
        bloquesPct: 0,
        tablasPct: 0,
        mithrilPct: 0,
        cristalPct: 0,
        plataPct: 0,
        reliquiasPct: 0,
        gemasPct: 0,
        joyasPct: 0
      }
    }
  ];

  for (const terreno of terrenos) {
    batch.set(db.collection("terrenos").doc(terreno.id), terreno, {
      merge: true
    });
  }

  const partidaRef = db.collection("partidas").doc("partida_prueba");

  batch.set(
    partidaRef,
    {
      nombre: "Partida de prueba",
      ronda: 1,
      estado: "activa",
      mapaId: "mapa_prueba",
      imagenMapaUrl: "",
      fechaInicio: admin.firestore.Timestamp.now(),
      fechaFin: null,
      diaActual: 1,
      totalDias: 60,
      horasProteccionInicial: 24,
      horasProteccionAtaque: 12,
      maxImperiosPorClan: 5,
      permitirRegistro: true,
      pasoDiaHora: "00:00",
      zonaHoraria: "America/Bogota",
      ultimoPasoDia: null,
      proximoPasoDia: null,
      contadorImperios: 0,
      contadorCiudades: 0,
      creadoEn: ahora,
      actualizadoEn: ahora
    },
    { merge: true }
  );

  const regiones = [
    {
      id: "region_1",
      numero: 1,
      nombre: "Tierras Centrales",
      terrenosPermitidos: ["llanura", "bosque", "rio"],
      imagenMapaUrl: "",
      creadoEn: ahora
    },
    {
      id: "region_2",
      numero: 2,
      nombre: "Cordillera Gris",
      terrenosPermitidos: ["montana", "bosque"],
      imagenMapaUrl: "",
      creadoEn: ahora
    },
    {
      id: "region_3",
      numero: 3,
      nombre: "Riberas del Norte",
      terrenosPermitidos: ["rio", "llanura"],
      imagenMapaUrl: "",
      creadoEn: ahora
    }
  ];

  for (const region of regiones) {
    batch.set(partidaRef.collection("regiones").doc(region.id), region, {
      merge: true
    });
  }

  await batch.commit();

  return {
    ok: true,
    mensaje: "Datos iniciales creados correctamente."
  };
});
