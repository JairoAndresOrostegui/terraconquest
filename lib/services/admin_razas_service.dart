import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRazasService {
  AdminRazasService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<QuerySnapshot<Map<String, dynamic>>> observarRazas() {
    return _firestore.collection('razas').orderBy('nombre').snapshots();
  }

  Future<void> guardarRaza({
    String? razaIdActual,
    required String codigo,
    required String nombre,
    required String descripcion,
    required String imagenUrl,
    required bool activo,
    required Map<String, int> bonos,
    required Map<String, int> penalizaciones,
  }) async {
    final codigoNormalizado = codigo.trim().toLowerCase();
    final data = {
      'codigo': codigoNormalizado,
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
      'imagenUrl': imagenUrl.trim(),
      'activo': activo,
      'bonos': bonos,
      'penalizaciones': penalizaciones,
      'actualizadoEn': FieldValue.serverTimestamp(),
    };

    final razasRef = _firestore.collection('razas');

    if (razaIdActual == null) {
      await razasRef.doc(codigoNormalizado).set({
        ...data,
        'creadoEn': FieldValue.serverTimestamp(),
      });
    } else {
      await razasRef.doc(razaIdActual).update(data);
    }
  }

  Future<void> eliminarRaza(String razaId) {
    return _firestore.collection('razas').doc(razaId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> observarPoliticas(String razaId) {
    return _firestore
        .collection('razas')
        .doc(razaId)
        .collection('politicas')
        .orderBy('nombre')
        .snapshots();
  }

  Future<void> guardarPolitica({
    required String razaId,
    String? politicaIdActual,
    required String codigo,
    required String nombre,
    required String descripcion,
    required bool activo,
    required Map<String, int> bonos,
    required Map<String, int> penalizaciones,
  }) async {
    final codigoNormalizado = codigo.trim().toLowerCase();
    final politicasRef = _firestore
        .collection('razas')
        .doc(razaId)
        .collection('politicas');
    final data = {
      'codigo': codigoNormalizado,
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
      'activo': activo,
      'bonos': bonos,
      'penalizaciones': penalizaciones,
      'actualizadoEn': FieldValue.serverTimestamp(),
    };

    if (politicaIdActual == null) {
      await politicasRef.doc(codigoNormalizado).set({
        ...data,
        'creadoEn': FieldValue.serverTimestamp(),
      });
    } else {
      await politicasRef.doc(politicaIdActual).update(data);
    }
  }

  Future<void> eliminarPolitica({
    required String razaId,
    required String politicaId,
  }) {
    return _firestore
        .collection('razas')
        .doc(razaId)
        .collection('politicas')
        .doc(politicaId)
        .delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> observarTropas(String razaId) {
    return _firestore
        .collection('razas')
        .doc(razaId)
        .collection('tropas')
        .snapshots();
  }

  Future<void> guardarTropa({
    required String razaId,
    String? tropaIdActual,
    required String codigo,
    required String nombre,
    required String descripcion,
    required int nivel,
    required int ataque,
    required int defensa,
    required int danio,
    required int vida,
    required int velocidad,
    required int moral,
    required String tipoAtaque,
    required String tipoDefensa,
    required String tipoMagia,
    required List<String> habilidades,
    required Map<String, int> costeCompra,
    required Map<String, int> mantenimiento,
    required Map<String, dynamic> desbloqueo,
    required bool activo,
  }) async {
    final codigoNormalizado = codigo.trim().toLowerCase();
    final tropaId = tropaIdActual ?? codigoNormalizado;
    final data = {
      'codigo': codigoNormalizado,
      'razaId': razaId,
      'nivel': nivel,
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
      'ataque': ataque,
      'defensa': defensa,
      'danio': danio,
      'vida': vida,
      'velocidad': velocidad,
      'moral': moral,
      'tipoAtaque': tipoAtaque.trim(),
      'tipoDefensa': tipoDefensa.trim(),
      'tipoMagia': tipoMagia.trim(),
      'habilidades': habilidades,
      'costeCompra': costeCompra,
      'mantenimiento': mantenimiento,
      'desbloqueo': desbloqueo,
      'activo': activo,
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
    await _firestore
        .collection('razas')
        .doc(razaId)
        .collection('tropas')
        .doc(tropaId)
        .set({
          ...data,
          if (tropaIdActual == null) 'creadoEn': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> eliminarTropa({
    required String razaId,
    required String tropaId,
  }) {
    return _firestore
        .collection('razas')
        .doc(razaId)
        .collection('tropas')
        .doc(tropaId)
        .delete();
  }
}
