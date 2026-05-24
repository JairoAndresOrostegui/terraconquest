import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class HeroesService {
  HeroesService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<QuerySnapshot<Map<String, dynamic>>> observarHeroesMercado({
    required String partidaId,
  }) {
    return _firestore
        .collection('partidas')
        .doc(partidaId)
        .collection('heroesMercado')
        .where('disponible', isEqualTo: true)
        .orderBy('clase')
        .orderBy('nivel')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> observarHeroesImperio({
    required String partidaId,
    required String imperioId,
  }) {
    return _firestore
        .collection('partidas')
        .doc(partidaId)
        .collection('heroes')
        .where('imperioId', isEqualTo: imperioId)
        .where('estado', isEqualTo: 'activo')
        .orderBy('nivel', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>> comprarHeroe({
    required String partidaId,
    required String imperioId,
    required String ofertaHeroeId,
    required String nombreHeroe,
    required String regionId,
  }) async {
    final callable = _functions.httpsCallable('comprarHeroe');

    final result = await callable.call<Map<String, dynamic>>({
      'partidaId': partidaId,
      'imperioId': imperioId,
      'ofertaHeroeId': ofertaHeroeId,
      'nombreHeroe': nombreHeroe,
      'regionId': regionId,
    });

    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> asignarTropasHeroe({
    required String partidaId,
    required String ciudadId,
    required String heroeId,
    required String tropaId,
    required int cantidad,
  }) async {
    final callable = _functions.httpsCallable('asignarTropasHeroe');

    final result = await callable.call<Map<String, dynamic>>({
      'partidaId': partidaId,
      'ciudadId': ciudadId,
      'heroeId': heroeId,
      'tropaId': tropaId,
      'cantidad': cantidad,
    });

    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> quitarTropasHeroe({
    required String partidaId,
    required String heroeId,
    required String ciudadDestinoId,
    required String tropaId,
    required int cantidad,
  }) async {
    final callable = _functions.httpsCallable('quitarTropasHeroe');

    final result = await callable.call<Map<String, dynamic>>({
      'partidaId': partidaId,
      'heroeId': heroeId,
      'ciudadDestinoId': ciudadDestinoId,
      'tropaId': tropaId,
      'cantidad': cantidad,
    });

    return Map<String, dynamic>.from(result.data);
  }
}
