import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRegionesService {
  AdminRegionesService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<QuerySnapshot<Map<String, dynamic>>> observarRegionesGlobales() {
    return _firestore.collection('regiones').orderBy('nombre').snapshots();
  }

  Future<void> guardarRegionGlobal({
    String? regionId,
    required String nombre,
    required String codigo,
    required String descripcion,
    required String imagenUrl,
    required bool activo,
    required List<String> terrenosPermitidos,
    required Map<String, int> bonos,
  }) async {
    final data = {
      'nombre': nombre.trim(),
      'codigo': codigo.trim().toUpperCase(),
      'descripcion': descripcion.trim(),
      'imagenUrl': imagenUrl.trim(),
      'activo': activo,
      'terrenosPermitidos': terrenosPermitidos,
      'bonos': bonos,
      'actualizadoEn': FieldValue.serverTimestamp(),
    };

    final regionesRef = _firestore.collection('regiones');

    if (regionId == null) {
      await regionesRef.add({
        ...data,
        'creadoEn': FieldValue.serverTimestamp(),
      });
    } else {
      await regionesRef.doc(regionId).update(data);
    }
  }

  Future<void> eliminarRegionGlobal(String regionId) {
    return _firestore.collection('regiones').doc(regionId).delete();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  obtenerTerrenosActivos() async {
    final snapshot =
        await _firestore
            .collection('terrenos')
            .where('activo', isEqualTo: true)
            .orderBy('nombre')
            .get();

    return snapshot.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  obtenerRegionesActivas() async {
    final snapshot =
        await _firestore
            .collection('regiones')
            .where('activo', isEqualTo: true)
            .orderBy('nombre')
            .get();

    return snapshot.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  obtenerRegionesParaPartidas() async {
    final snapshot =
        await _firestore.collection('regiones').orderBy('nombre').get();

    return snapshot.docs;
  }
}
