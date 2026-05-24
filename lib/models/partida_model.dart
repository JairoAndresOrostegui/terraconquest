import 'package:cloud_firestore/cloud_firestore.dart';

class PartidaModel {
  const PartidaModel({
    required this.id,
    required this.nombre,
    required this.ronda,
    required this.estado,
    required this.mapaId,
    required this.fechaInicio,
    required this.fechaFin,
    required this.diaActual,
    required this.totalDias,
    required this.permitirRegistro,
    required this.horasProteccionInicial,
    required this.maxImperiosPorClan,
  });

  final String id;
  final String nombre;
  final int ronda;
  final String estado;
  final String mapaId;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int diaActual;
  final int totalDias;
  final bool permitirRegistro;
  final int horasProteccionInicial;
  final int maxImperiosPorClan;

  factory PartidaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return PartidaModel(
      id: doc.id,
      nombre: data['nombre'] as String? ?? '',
      ronda: data['ronda'] as int? ?? 0,
      estado: data['estado'] as String? ?? 'futura',
      mapaId: data['mapaId'] as String? ?? '',
      fechaInicio: (data['fechaInicio'] as Timestamp?)?.toDate(),
      fechaFin: (data['fechaFin'] as Timestamp?)?.toDate(),
      diaActual: data['diaActual'] as int? ?? 0,
      totalDias: data['totalDias'] as int? ?? 0,
      permitirRegistro: data['permitirRegistro'] as bool? ?? false,
      horasProteccionInicial: data['horasProteccionInicial'] as int? ?? 0,
      maxImperiosPorClan: data['maxImperiosPorClan'] as int? ?? 0,
    );
  }
}
