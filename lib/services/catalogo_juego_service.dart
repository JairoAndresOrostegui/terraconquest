import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/raza_model.dart';
import '../models/region_model.dart';
import '../models/terreno_model.dart';

class CatalogoJuegoService {
  CatalogoJuegoService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<RazaModel>> obtenerRazasActivas() async {
    final snapshot = await _firestore
        .collection('razas')
        .where('activo', isEqualTo: true)
        .orderBy('nombre')
        .get();

    return snapshot.docs.map((doc) => RazaModel.fromFirestore(doc)).toList();
  }

  Future<List<RegionModel>> obtenerRegionesDePartida(String partidaId) async {
    final snapshot = await _firestore
        .collection('partidas')
        .doc(partidaId)
        .collection('regiones')
        .orderBy('numero')
        .get();

    return snapshot.docs.map((doc) => RegionModel.fromFirestore(doc)).toList();
  }

  Future<List<TerrenoModel>> obtenerTerrenosActivos() async {
    final snapshot = await _firestore
        .collection('terrenos')
        .where('activo', isEqualTo: true)
        .orderBy('nombre')
        .get();

    return snapshot.docs.map((doc) => TerrenoModel.fromFirestore(doc)).toList();
  }
}
