import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPartidasCrudService {
  AdminPartidasCrudService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<QuerySnapshot<Map<String, dynamic>>> observarPartidas() {
    return _firestore
        .collection('partidas')
        .orderBy('creadoEn', descending: true)
        .snapshots();
  }

  Future<void> crearPartida({
    required String nombre,
    required int ronda,
    required String estado,
    required String mapaId,
    required DateTime fechaInicio,
    DateTime? fechaFin,
    required int totalDias,
    required int horasProteccionInicial,
    required int maxImperiosPorClan,
    required bool permitirRegistro,
  }) async {
    await _firestore.collection('partidas').add({
      'nombre': nombre.trim(),
      'ronda': ronda,
      'estado': estado,
      'mapaId': mapaId.trim(),
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': fechaFin == null ? null : Timestamp.fromDate(fechaFin),
      'diaActual': 1,
      'totalDias': totalDias,
      'horasProteccionInicial': horasProteccionInicial,
      'maxImperiosPorClan': maxImperiosPorClan,
      'permitirRegistro': permitirRegistro,
      'pasoDiaHora': '00:00',
      'zonaHoraria': 'America/Bogota',
      'ultimoPasoDia': null,
      'proximoPasoDia': null,
      'contadorImperios': 0,
      'contadorCiudades': 0,
      'creadoEn': FieldValue.serverTimestamp(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> actualizarPartida({
    required String partidaId,
    required String nombre,
    required int ronda,
    required String estado,
    required String mapaId,
    required DateTime fechaInicio,
    DateTime? fechaFin,
    required int diaActual,
    required int totalDias,
    required int horasProteccionInicial,
    required int maxImperiosPorClan,
    required bool permitirRegistro,
  }) async {
    await _firestore.collection('partidas').doc(partidaId).update({
      'nombre': nombre.trim(),
      'ronda': ronda,
      'estado': estado,
      'mapaId': mapaId.trim(),
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': fechaFin == null ? null : Timestamp.fromDate(fechaFin),
      'diaActual': diaActual,
      'totalDias': totalDias,
      'horasProteccionInicial': horasProteccionInicial,
      'maxImperiosPorClan': maxImperiosPorClan,
      'permitirRegistro': permitirRegistro,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> eliminarPartida(String partidaId) {
    return _firestore.collection('partidas').doc(partidaId).delete();
  }
}
