import 'package:cloud_firestore/cloud_firestore.dart';

class RazaModel {
  const RazaModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.activo,
    required this.bonos,
    required this.penalizaciones,
  });

  final String id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final String imagenUrl;
  final bool activo;
  final Map<String, dynamic> bonos;
  final Map<String, dynamic> penalizaciones;

  factory RazaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return RazaModel(
      id: doc.id,
      codigo: data['codigo'] as String? ?? doc.id,
      nombre: data['nombre'] as String? ?? '',
      descripcion: data['descripcion'] as String? ?? '',
      imagenUrl: data['imagenUrl'] as String? ?? '',
      activo: data['activo'] as bool? ?? true,
      bonos: Map<String, dynamic>.from(data['bonos'] ?? {}),
      penalizaciones: Map<String, dynamic>.from(data['penalizaciones'] ?? {}),
    );
  }
}
