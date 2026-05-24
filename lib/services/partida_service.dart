import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/imperio_resumen_model.dart';
import '../models/partida_model.dart';

class PartidaService {
  PartidaService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<PartidaModel>> observarPartidasDisponibles() {
    return _firestore
        .collection('partidas')
        .where('estado', whereIn: ['futura', 'activa'])
        .orderBy('fechaInicio')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PartidaModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<ImperioResumenModel?> obtenerImperioDelUsuarioEnPartida({
    required String partidaId,
    required String userId,
  }) async {
    final snapshot = await _firestore
        .collection('partidas')
        .doc(partidaId)
        .collection('imperios')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return ImperioResumenModel.fromFirestore(snapshot.docs.first);
  }
}
