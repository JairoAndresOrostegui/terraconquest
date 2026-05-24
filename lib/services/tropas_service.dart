import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tropa_ciudad_model.dart';

class TropasService {
  TropasService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<TropaCiudadModel>> observarTropasCiudad({
    required String partidaId,
    required String ciudadId,
  }) {
    return _firestore
        .collection('partidas')
        .doc(partidaId)
        .collection('ciudades')
        .doc(ciudadId)
        .collection('tropas')
        .orderBy('nivel')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(TropaCiudadModel.fromFirestore).toList();
    });
  }

  Future<List<Map<String, dynamic>>> obtenerTropasDisponibles({
    required String partidaId,
    required String ciudadId,
  }) async {
    final callable = _functions.httpsCallable('obtenerTropasDisponibles');

    final result = await callable.call<List<dynamic>>({
      'partidaId': partidaId,
      'ciudadId': ciudadId,
    });

    return result.data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> moverTropasCiudad({
    required String partidaId,
    required String ciudadOrigenId,
    required String ciudadDestinoId,
    required String tropaId,
    required int cantidad,
  }) async {
    final callable = _functions.httpsCallable('moverTropasCiudad');

    final result = await callable.call<Map<String, dynamic>>({
      'partidaId': partidaId,
      'ciudadOrigenId': ciudadOrigenId,
      'ciudadDestinoId': ciudadDestinoId,
      'tropaId': tropaId,
      'cantidad': cantidad,
    });

    return Map<String, dynamic>.from(result.data);
  }
}
