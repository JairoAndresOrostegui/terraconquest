import 'package:cloud_firestore/cloud_firestore.dart';

class RegionModel {
  const RegionModel({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.descripcion,
    required this.activo,
    required this.terrenosPermitidos,
    required this.bonos,
  });

  final String id;
  final String nombre;
  final String codigo;
  final String descripcion;
  final bool activo;
  final List<String> terrenosPermitidos;
  final Map<String, dynamic> bonos;

  factory RegionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return RegionModel(
      id: doc.id,
      nombre: data['nombre'] as String? ?? '',
      codigo: data['codigo'] as String? ?? '',
      descripcion: data['descripcion'] as String? ?? '',
      activo: data['activo'] as bool? ?? true,
      terrenosPermitidos: List<String>.from(data['terrenosPermitidos'] ?? []),
      bonos: Map<String, dynamic>.from(data['bonos'] ?? {}),
    );
  }
}
