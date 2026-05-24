import 'package:cloud_firestore/cloud_firestore.dart';

class RazaModel {
  const RazaModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.activo,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final String imagenUrl;
  final bool activo;

  factory RazaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return RazaModel(
      id: doc.id,
      nombre: data['nombre'] as String? ?? '',
      descripcion: data['descripcion'] as String? ?? '',
      imagenUrl: data['imagenUrl'] as String? ?? '',
      activo: data['activo'] as bool? ?? true,
    );
  }
}
