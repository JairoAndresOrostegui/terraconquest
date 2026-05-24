import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRegionesService {
  AdminRegionesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<QuerySnapshot<Map<String, dynamic>>> observarRegiones(
    String partidaId,
  ) {
    return _firestore
        .collection('partidas')
        .doc(partidaId)
        .collection('regiones')
        .orderBy('numero')
        .snapshots();
  }

  Future<void> guardarRegion({
    required String partidaId,
    String? regionId,
    required int numero,
    required String nombre,
    required List<String> terrenosPermitidos,
    String imagenMapaUrl = '',
  }) async {
    final data = {
      'numero': numero,
      'nombre': nombre.trim(),
      'terrenosPermitidos': terrenosPermitidos,
      'imagenMapaUrl': imagenMapaUrl.trim(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    };

    final regionesRef = _firestore
        .collection('partidas')
        .doc(partidaId)
        .collection('regiones');

    if (regionId == null) {
      await regionesRef.add({
        ...data,
        'creadoEn': FieldValue.serverTimestamp(),
      });
    } else {
      await regionesRef.doc(regionId).update(data);
    }
  }

  Future<void> eliminarRegion({
    required String partidaId,
    required String regionId,
  }) {
    return _firestore
        .collection('partidas')
        .doc(partidaId)
        .collection('regiones')
        .doc(regionId)
        .delete();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      obtenerTerrenosActivos() async {
    final snapshot = await _firestore
        .collection('terrenos')
        .where('activo', isEqualTo: true)
        .orderBy('nombre')
        .get();

    return snapshot.docs;
  }
}
