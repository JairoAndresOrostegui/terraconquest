import 'package:cloud_functions/cloud_functions.dart';

class AdminPartidaService {
  AdminPartidaService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> pasarDiaPartida({
    required String partidaId,
  }) async {
    final callable = _functions.httpsCallable('pasarDiaPartida');

    final result = await callable.call<Map<String, dynamic>>({
      'partidaId': partidaId,
    });

    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> desbloquearPasoDia({
    required String partidaId,
  }) async {
    final callable = _functions.httpsCallable('desbloquearPasoDia');

    final result = await callable.call<Map<String, dynamic>>({
      'partidaId': partidaId,
    });

    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> seedDatosIniciales() async {
    final callable = _functions.httpsCallable('seedDatosIniciales');

    final result = await callable.call<Map<String, dynamic>>();

    return Map<String, dynamic>.from(result.data);
  }
}
