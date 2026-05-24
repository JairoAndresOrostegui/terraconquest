import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTerrenosService {
  AdminTerrenosService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<QuerySnapshot<Map<String, dynamic>>> observarTerrenos() {
    return _firestore.collection('terrenos').orderBy('nombre').snapshots();
  }

  Future<void> guardarTerreno({
    String? terrenoId,
    required String nombre,
    required String codigo,
    required String descripcion,
    required String imagenUrl,
    required bool activo,
    required Map<String, int> bonos,
  }) async {
    final data = {
      'nombre': nombre.trim(),
      'codigo': codigo.trim().toUpperCase(),
      'descripcion': descripcion.trim(),
      'imagenUrl': imagenUrl.trim(),
      'activo': activo,
      'bonos': bonos,
      'actualizadoEn': FieldValue.serverTimestamp(),
    };

    final terrenosRef = _firestore.collection('terrenos');

    if (terrenoId == null) {
      await terrenosRef.add({
        ...data,
        'creadoEn': FieldValue.serverTimestamp(),
      });
    } else {
      await terrenosRef.doc(terrenoId).update(data);
    }
  }

  Future<void> eliminarTerreno(String terrenoId) {
    return _firestore.collection('terrenos').doc(terrenoId).delete();
  }
}
