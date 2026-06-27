import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/raza_model.dart';
import '../models/region_model.dart';
import '../models/terreno_model.dart';

class CatalogoJuegoService {
  CatalogoJuegoService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<RazaModel>> obtenerRazasActivas() async {
    final snapshot =
        await _firestore
            .collection('razas')
            .where('activo', isEqualTo: true)
            .orderBy('nombre')
            .get();

    return snapshot.docs.map((doc) => RazaModel.fromFirestore(doc)).toList();
  }

  Future<List<RegionModel>> obtenerRegionesDePartida(String partidaId) async {
    final partida =
        await _firestore.collection('partidas').doc(partidaId).get();
    final regionesIds = List<String>.from(
      partida.data()?['regionesDisponibles'] ?? [],
    );

    if (regionesIds.isEmpty) return [];

    final regiones = <RegionModel>[];

    for (var i = 0; i < regionesIds.length; i += 10) {
      final bloque = regionesIds.skip(i).take(10).toList();
      final snapshot =
          await _firestore
              .collection('regiones')
              .where(FieldPath.documentId, whereIn: bloque)
              .get();

      regiones.addAll(
        snapshot.docs.map((doc) => RegionModel.fromFirestore(doc)),
      );
    }

    regiones.sort((a, b) => a.nombre.compareTo(b.nombre));
    return regiones;
  }

  Future<List<TerrenoModel>> obtenerTerrenosActivos() async {
    final snapshot =
        await _firestore
            .collection('terrenos')
            .where('activo', isEqualTo: true)
            .orderBy('nombre')
            .get();

    return snapshot.docs.map((doc) => TerrenoModel.fromFirestore(doc)).toList();
  }
}
