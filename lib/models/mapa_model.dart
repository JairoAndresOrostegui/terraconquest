import 'model_helpers.dart';

class MapaModel {
  const MapaModel({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.totalRegiones,
    required this.activo,
    this.creadoEn,
    this.actualizadoEn,
  });

  final String? id;
  final String nombre;
  final String descripcion;
  final int totalRegiones;
  final bool activo;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  factory MapaModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return MapaModel(
      id: id,
      nombre: stringFromValue(map['nombre']),
      descripcion: stringFromValue(map['descripcion']),
      totalRegiones: intFromValue(map['totalRegiones']),
      activo: boolFromValue(map['activo'], fallback: true),
      creadoEn: dateFromValue(map['creadoEn']),
      actualizadoEn: dateFromValue(map['actualizadoEn']),
    );
  }

  Map<String, dynamic> toMap() {
    return cleanMap({
      'nombre': nombre,
      'descripcion': descripcion,
      'totalRegiones': totalRegiones,
      'activo': activo,
      'creadoEn': creadoEn,
      'actualizadoEn': actualizadoEn,
    });
  }
}
