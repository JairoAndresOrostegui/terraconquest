import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ciudad_model.dart';
import '../models/tropa_ciudad_model.dart';

class CiudadConTropas {
  const CiudadConTropas({
    required this.ciudad,
    required this.tropas,
  });

  final CiudadModel ciudad;
  final List<TropaCiudadModel> tropas;

  int get totalTropas {
    return tropas.fold(0, (total, tropa) => total + tropa.cantidad);
  }

  int get totalNiveles {
    return tropas.fold(0, (total, tropa) => total + tropa.nivelesTotales);
  }
}

class EjercitoService {
  EjercitoService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<CiudadConTropas>> obtenerEjercitoImperio({
    required String partidaId,
    required String imperioId,
  }) async {
    final ciudadesSnap = await _firestore
        .collection('partidas')
        .doc(partidaId)
        .collection('ciudades')
        .where('imperioId', isEqualTo: imperioId)
        .orderBy('nombre')
        .get();

    final resultado = <CiudadConTropas>[];

    for (final ciudadDoc in ciudadesSnap.docs) {
      final tropasSnap = await ciudadDoc.reference
          .collection('tropas')
          .orderBy('nivel')
          .get();
      final tropas = tropasSnap.docs
          .map((doc) => TropaCiudadModel.fromFirestore(doc))
          .toList();

      resultado.add(
        CiudadConTropas(
          ciudad: CiudadModel.fromFirestore(ciudadDoc),
          tropas: tropas,
        ),
      );
    }

    return resultado;
  }
}
