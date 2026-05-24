import 'package:cloud_firestore/cloud_firestore.dart';

class ImperioResumenModel {
  const ImperioResumenModel({
    required this.id,
    required this.userId,
    required this.partidaId,
    required this.nombre,
    required this.razaId,
    required this.estado,
    required this.valor,
    required this.ranking,
  });

  final String id;
  final String userId;
  final String partidaId;
  final String nombre;
  final String razaId;
  final String estado;
  final int valor;
  final int ranking;

  factory ImperioResumenModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final partidaId = doc.reference.parent.parent?.id ?? '';

    return ImperioResumenModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      partidaId: partidaId,
      nombre: data['nombre'] as String? ?? '',
      razaId: data['razaId'] as String? ?? '',
      estado: data['estado'] as String? ?? 'activo',
      valor: data['valor'] as int? ?? 0,
      ranking: data['ranking'] as int? ?? 0,
    );
  }
}
