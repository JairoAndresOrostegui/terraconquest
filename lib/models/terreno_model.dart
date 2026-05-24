import 'package:cloud_firestore/cloud_firestore.dart';

class TerrenoModel {
  const TerrenoModel({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.descripcion,
    required this.imagenUrl,
    required this.activo,
  });

  final String id;
  final String nombre;
  final String codigo;
  final String descripcion;
  final String imagenUrl;
  final bool activo;

  factory TerrenoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TerrenoModel(
      id: doc.id,
      nombre: data['nombre'] as String? ?? '',
      codigo: data['codigo'] as String? ?? '',
      descripcion: data['descripcion'] as String? ?? '',
      imagenUrl: data['imagenUrl'] as String? ?? '',
      activo: data['activo'] as bool? ?? true,
    );
  }
}
