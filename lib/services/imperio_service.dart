import 'package:cloud_functions/cloud_functions.dart';

class ImperioService {
  ImperioService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> crearImperio({
    required String partidaId,
    required String razaId,
    required String nombreImperio,
    required String nombreCiudad,
    required String regionId,
    required String terrenoId,
  }) async {
    final callable = _functions.httpsCallable('crearImperio');

    final result = await callable.call<Map<String, dynamic>>({
      'partidaId': partidaId,
      'razaId': razaId,
      'nombreImperio': nombreImperio,
      'nombreCiudad': nombreCiudad,
      'regionId': regionId,
      'terrenoId': terrenoId,
    });

    return Map<String, dynamic>.from(result.data);
  }
}
