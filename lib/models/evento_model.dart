import 'package:cloud_firestore/cloud_firestore.dart';

class EventoModel {
  const EventoModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.ciudadId,
    required this.imperioId,
    required this.clanId,
    required this.visibleGlobal,
    required this.visibleClanId,
    required this.dia,
    required this.creadoEn,
  });

  final String id;
  final String tipo;
  final String titulo;
  final String descripcion;
  final String? ciudadId;
  final String? imperioId;
  final String? clanId;
  final bool visibleGlobal;
  final String? visibleClanId;
  final int dia;
  final DateTime? creadoEn;

  factory EventoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return EventoModel(
      id: doc.id,
      tipo: data['tipo']?.toString() ?? '',
      titulo: data['titulo']?.toString() ?? '',
      descripcion: data['descripcion']?.toString() ?? '',
      ciudadId: data['ciudadId'] as String?,
      imperioId: data['imperioId'] as String?,
      clanId: data['clanId'] as String?,
      visibleGlobal: data['visibleGlobal'] as bool? ?? false,
      visibleClanId: data['visibleClanId'] as String?,
      dia: (data['dia'] as num?)?.toInt() ?? 0,
      creadoEn: (data['creadoEn'] as Timestamp?)?.toDate(),
    );
  }
}
