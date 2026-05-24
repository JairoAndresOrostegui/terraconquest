import 'package:cloud_firestore/cloud_firestore.dart';

class ImperioModel {
  const ImperioModel({
    required this.id,
    required this.userId,
    required this.partidaId,
    required this.nombre,
    required this.razaId,
    required this.estado,
    required this.recursos,
    required this.produccionDiaria,
    required this.turnos,
    required this.fama,
    required this.indiceBelico,
    required this.valor,
    required this.ranking,
    required this.totalCiudades,
    required this.totalHeroes,
    required this.totalPoblacion,
    required this.totalTropas,
  });

  final String id;
  final String userId;
  final String partidaId;
  final String nombre;
  final String razaId;
  final String estado;
  final Map<String, dynamic> recursos;
  final Map<String, dynamic> produccionDiaria;
  final int turnos;
  final int fama;
  final int indiceBelico;
  final int valor;
  final int ranking;
  final int totalCiudades;
  final int totalHeroes;
  final int totalPoblacion;
  final int totalTropas;

  factory ImperioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final partidaId = doc.reference.parent.parent?.id ?? '';

    return ImperioModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      partidaId: data['partidaId'] as String? ?? partidaId,
      nombre: data['nombre'] as String? ?? '',
      razaId: data['razaId'] as String? ?? '',
      estado: data['estado'] as String? ?? 'activo',
      recursos: Map<String, dynamic>.from(data['recursos'] ?? {}),
      produccionDiaria: Map<String, dynamic>.from(
        data['produccionDiaria'] ?? {},
      ),
      turnos: data['turnos'] as int? ?? 0,
      fama: data['fama'] as int? ?? 0,
      indiceBelico: data['indiceBelico'] as int? ?? 0,
      valor: data['valor'] as int? ?? 0,
      ranking: data['ranking'] as int? ?? 0,
      totalCiudades: data['totalCiudades'] as int? ?? 0,
      totalHeroes: data['totalHeroes'] as int? ?? 0,
      totalPoblacion: data['totalPoblacion'] as int? ?? 0,
      totalTropas: data['totalTropas'] as int? ?? 0,
    );
  }
}
