import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ciudad_model.dart';
import '../models/imperio_model.dart';

class DashboardImperioService {
  DashboardImperioService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<ImperioModel> observarImperio({
    required String partidaId,
    required String imperioId,
  }) {
    return _firestore
        .collection('partidas')
        .doc(partidaId)
        .collection('imperios')
        .doc(imperioId)
        .snapshots()
        .map((doc) => ImperioModel.fromFirestore(doc));
  }

  Stream<List<CiudadModel>> observarCiudadesDelImperio({
    required String partidaId,
    required String imperioId,
  }) {
    return _firestore
        .collection('partidas')
        .doc(partidaId)
        .collection('ciudades')
        .where('imperioId', isEqualTo: imperioId)
        .orderBy('creadoEn')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CiudadModel.fromFirestore(doc)).toList();
    });
  }
}
