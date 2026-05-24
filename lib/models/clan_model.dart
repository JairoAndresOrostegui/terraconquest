import 'model_helpers.dart';
import 'model_types.dart';

class ClanModel {
  const ClanModel({
    this.id,
    required this.nombre,
    required this.nombreLower,
    required this.tag,
    required this.liderImperioId,
    required this.tipoIngreso,
    required this.maxImperios,
    required this.valor,
    required this.ranking,
    required this.rankingAnterior,
    required this.totalImperios,
    required this.totalPoblacion,
    required this.totalCiudades,
    required this.totalHeroes,
    required this.alianzas,
    required this.guerras,
    required this.instrucciones,
    required this.descripcion,
    required this.estado,
    this.creadoEn,
    this.actualizadoEn,
  });

  final String? id;
  final String nombre;
  final String nombreLower;
  final String tag;
  final String liderImperioId;
  final ClanTipoIngreso tipoIngreso;
  final int maxImperios;
  final int valor;
  final int ranking;
  final int rankingAnterior;
  final int totalImperios;
  final int totalPoblacion;
  final int totalCiudades;
  final int totalHeroes;
  final List<String> alianzas;
  final List<String> guerras;
  final String instrucciones;
  final String descripcion;
  final ClanEstado estado;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  factory ClanModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ClanModel(
      id: id,
      nombre: stringFromValue(map['nombre']),
      nombreLower: stringFromValue(map['nombreLower']),
      tag: stringFromValue(map['tag']),
      liderImperioId: stringFromValue(map['liderImperioId']),
      tipoIngreso: enumFromValue(
        ClanTipoIngreso.values,
        map['tipoIngreso'] as String?,
        ClanTipoIngreso.privado,
        (item) => item.value,
      ),
      maxImperios: intFromValue(map['maxImperios']),
      valor: intFromValue(map['valor']),
      ranking: intFromValue(map['ranking']),
      rankingAnterior: intFromValue(map['rankingAnterior']),
      totalImperios: intFromValue(map['totalImperios']),
      totalPoblacion: intFromValue(map['totalPoblacion']),
      totalCiudades: intFromValue(map['totalCiudades']),
      totalHeroes: intFromValue(map['totalHeroes']),
      alianzas: stringListFromValue(map['alianzas']),
      guerras: stringListFromValue(map['guerras']),
      instrucciones: stringFromValue(map['instrucciones']),
      descripcion: stringFromValue(map['descripcion']),
      estado: enumFromValue(
        ClanEstado.values,
        map['estado'] as String?,
        ClanEstado.activo,
        (item) => item.value,
      ),
      creadoEn: dateFromValue(map['creadoEn']),
      actualizadoEn: dateFromValue(map['actualizadoEn']),
    );
  }

  Map<String, dynamic> toMap() {
    return cleanMap({
      'nombre': nombre,
      'nombreLower': nombreLower,
      'tag': tag,
      'liderImperioId': liderImperioId,
      'tipoIngreso': tipoIngreso.value,
      'maxImperios': maxImperios,
      'valor': valor,
      'ranking': ranking,
      'rankingAnterior': rankingAnterior,
      'totalImperios': totalImperios,
      'totalPoblacion': totalPoblacion,
      'totalCiudades': totalCiudades,
      'totalHeroes': totalHeroes,
      'alianzas': alianzas,
      'guerras': guerras,
      'instrucciones': instrucciones,
      'descripcion': descripcion,
      'estado': estado.value,
      'creadoEn': creadoEn,
      'actualizadoEn': actualizadoEn,
    });
  }
}
