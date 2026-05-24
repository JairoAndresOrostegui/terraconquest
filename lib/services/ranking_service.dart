import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ranking_imperio_model.dart';

class RankingService {
  RankingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<RankingImperioModel>> observarRankingImperios({
    required String partidaId,
    int limite = 100,
  }) {
    return _firestore
        .collection('partidas')
        .doc(partidaId)
        .collection('rankingsImperios')
        .orderBy('ranking')
        .limit(limite)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(RankingImperioModel.fromFirestore).toList();
    });
  }
}
