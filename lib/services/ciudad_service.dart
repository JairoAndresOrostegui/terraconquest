import 'package:cloud_functions/cloud_functions.dart';

class CiudadService {
  CiudadService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> mejorarEdificio({
    required String partidaId,
    required String ciudadId,
    required String edificioId,
  }) async {
    final callable = _functions.httpsCallable('mejorarEdificio');

    final result = await callable.call<Map<String, dynamic>>({
      'partidaId': partidaId,
      'ciudadId': ciudadId,
      'edificioId': edificioId,
    });

    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> fundarCiudad({
    required String partidaId,
    required String imperioId,
    required String nombreCiudad,
    required String regionId,
    required String terrenoId,
  }) async {
    final callable = _functions.httpsCallable('fundarCiudad');

    final result = await callable.call<Map<String, dynamic>>({
      'partidaId': partidaId,
      'imperioId': imperioId,
      'nombreCiudad': nombreCiudad,
      'regionId': regionId,
      'terrenoId': terrenoId,
    });

    return Map<String, dynamic>.from(result.data);
  }

  Future<void> cambiarImpuestos({
    required String partidaId,
    required String ciudadId,
    required int impuestosPct,
  }) async {
    final callable = _functions.httpsCallable('cambiarImpuestosCiudad');

    await callable.call<void>({
      'partidaId': partidaId,
      'ciudadId': ciudadId,
      'impuestosPct': impuestosPct,
    });
  }
}
