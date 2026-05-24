import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/evento_model.dart';

class EventosService {
  EventosService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<EventoModel>> observarEventosImperio({
    required String partidaId,
    required String imperioId,
  }) {
    return _firestore
        .collection('partidas')
        .doc(partidaId)
        .collection('eventos')
        .where('imperioId', isEqualTo: imperioId)
        .orderBy('creadoEn', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(EventoModel.fromFirestore).toList();
    });
  }

  Stream<List<EventoModel>> observarEventosGlobales({
    required String partidaId,
  }) {
    return _firestore
        .collection('partidas')
        .doc(partidaId)
        .collection('eventos')
        .where('visibleGlobal', isEqualTo: true)
        .orderBy('creadoEn', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(EventoModel.fromFirestore).toList();
    });
  }
}
