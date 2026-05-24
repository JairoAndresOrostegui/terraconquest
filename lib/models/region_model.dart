import 'package:cloud_firestore/cloud_firestore.dart';

class RegionModel {
  const RegionModel({
    required this.id,
    required this.numero,
    required this.nombre,
    required this.terrenosPermitidos,
  });

  final String id;
  final int numero;
  final String nombre;
  final List<String> terrenosPermitidos;

  factory RegionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return RegionModel(
      id: doc.id,
      numero: data['numero'] as int? ?? 0,
      nombre: data['nombre'] as String? ?? '',
      terrenosPermitidos: List<String>.from(data['terrenosPermitidos'] ?? []),
    );
  }
}
