import 'model_helpers.dart';
import 'model_types.dart';

class HeroeModel {
  const HeroeModel({
    this.id,
    required this.imperioId,
    this.clanId,
    required this.nombre,
    required this.nombreLower,
    required this.clase,
    required this.razaId,
    required this.nivel,
    required this.experiencia,
    required this.regionId,
    required this.regionNumero,
    this.ciudadId,
    this.monturaId,
    required this.ataque,
    required this.defensa,
    required this.danio,
    required this.vida,
    required this.velocidad,
    required this.moral,
    required this.puntosDesarrollo,
    required this.tropas,
    required this.totalTropas,
    required this.victorias,
    this.protegidoHasta,
    required this.capturado,
    this.capturadoPorImperioId,
    this.capturadoEn,
    required this.costeRescate,
    required this.estado,
    this.creadoEn,
    this.actualizadoEn,
  });

  final String? id;
  final String imperioId;
  final String? clanId;
  final String nombre;
  final String nombreLower;
  final HeroeClase clase;
  final String razaId;
  final int nivel;
  final int experiencia;
  final String regionId;
  final int regionNumero;
  final String? ciudadId;
  final String? monturaId;
  final int ataque;
  final int defensa;
  final int danio;
  final int vida;
  final int velocidad;
  final int moral;
  final int puntosDesarrollo;
  final Map<String, int> tropas;
  final int totalTropas;
  final int victorias;
  final DateTime? protegidoHasta;
  final bool capturado;
  final String? capturadoPorImperioId;
  final DateTime? capturadoEn;
  final int costeRescate;
  final HeroeEstado estado;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  factory HeroeModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return HeroeModel(
      id: id,
      imperioId: stringFromValue(map['imperioId']),
      clanId: nullableStringFromValue(map['clanId']),
      nombre: stringFromValue(map['nombre']),
      nombreLower: stringFromValue(map['nombreLower']),
      clase: enumFromValue(
        HeroeClase.values,
        map['clase'] as String?,
        HeroeClase.guerrero,
        (item) => item.value,
      ),
      razaId: stringFromValue(map['razaId']),
      nivel: intFromValue(map['nivel']),
      experiencia: intFromValue(map['experiencia']),
      regionId: stringFromValue(map['regionId']),
      regionNumero: intFromValue(map['regionNumero']),
      ciudadId: nullableStringFromValue(map['ciudadId']),
      monturaId: nullableStringFromValue(map['monturaId']),
      ataque: intFromValue(map['ataque']),
      defensa: intFromValue(map['defensa']),
      danio: intFromValue(map['danio']),
      vida: intFromValue(map['vida']),
      velocidad: intFromValue(map['velocidad']),
      moral: intFromValue(map['moral']),
      puntosDesarrollo: intFromValue(map['puntosDesarrollo']),
      tropas: intMapFromValue(map['tropas']),
      totalTropas: intFromValue(map['totalTropas']),
      victorias: intFromValue(map['victorias']),
      protegidoHasta: dateFromValue(map['protegidoHasta']),
      capturado: boolFromValue(map['capturado']),
      capturadoPorImperioId: nullableStringFromValue(map['capturadoPorImperioId']),
      capturadoEn: dateFromValue(map['capturadoEn']),
      costeRescate: intFromValue(map['costeRescate']),
      estado: enumFromValue(
        HeroeEstado.values,
        map['estado'] as String?,
        HeroeEstado.activo,
        (item) => item.value,
      ),
      creadoEn: dateFromValue(map['creadoEn']),
      actualizadoEn: dateFromValue(map['actualizadoEn']),
    );
  }

  Map<String, dynamic> toMap() {
    return cleanMap({
      'imperioId': imperioId,
      'clanId': clanId,
      'nombre': nombre,
      'nombreLower': nombreLower,
      'clase': clase.value,
      'razaId': razaId,
      'nivel': nivel,
      'experiencia': experiencia,
      'regionId': regionId,
      'regionNumero': regionNumero,
      'ciudadId': ciudadId,
      'monturaId': monturaId,
      'ataque': ataque,
      'defensa': defensa,
      'danio': danio,
      'vida': vida,
      'velocidad': velocidad,
      'moral': moral,
      'puntosDesarrollo': puntosDesarrollo,
      'tropas': tropas,
      'totalTropas': totalTropas,
      'victorias': victorias,
      'protegidoHasta': protegidoHasta,
      'capturado': capturado,
      'capturadoPorImperioId': capturadoPorImperioId,
      'capturadoEn': capturadoEn,
      'costeRescate': costeRescate,
      'estado': estado.value,
      'creadoEn': creadoEn,
      'actualizadoEn': actualizadoEn,
    });
  }
}
