import 'package:cloud_firestore/cloud_firestore.dart';

class CiudadModel {
  const CiudadModel({
    required this.id,
    required this.imperioId,
    required this.partidaId,
    required this.nombre,
    required this.regionId,
    required this.terrenoId,
    required this.poblacion,
    required this.estado,
    required this.moral,
    required this.corrupcion,
    required this.felicidad,
    required this.higiene,
    required this.desempleo,
    required this.religion,
    required this.cultura,
    required this.impuestosPct,
    required this.produccionDiaria,
    required this.consumoDiario,
    required this.edificios,
    required this.nivelesTropasDefensaActuales,
    required this.nivelesTropasDefensaMinimos,
    required this.totalEdificios,
  });

  final String id;
  final String imperioId;
  final String partidaId;
  final String nombre;
  final String regionId;
  final String terrenoId;
  final int poblacion;
  final String estado;
  final int moral;
  final int corrupcion;
  final int felicidad;
  final int higiene;
  final int desempleo;
  final int religion;
  final int cultura;
  final int impuestosPct;
  final Map<String, dynamic> produccionDiaria;
  final Map<String, dynamic> consumoDiario;
  final Map<String, dynamic> edificios;
  final int nivelesTropasDefensaActuales;
  final int nivelesTropasDefensaMinimos;
  final int totalEdificios;

  factory CiudadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final partidaId = doc.reference.parent.parent?.id ?? '';

    return CiudadModel(
      id: doc.id,
      imperioId: data['imperioId'] as String? ?? '',
      partidaId: data['partidaId'] as String? ?? partidaId,
      nombre: data['nombre'] as String? ?? '',
      regionId: data['regionId'] as String? ?? '',
      terrenoId: data['terrenoId'] as String? ?? '',
      poblacion: data['poblacion'] as int? ?? 0,
      estado: data['estado'] as String? ?? 'activa',
      moral: data['moral'] as int? ?? 0,
      corrupcion: data['corrupcion'] as int? ?? 0,
      felicidad: data['felicidad'] as int? ?? 0,
      higiene: data['higiene'] as int? ?? 0,
      desempleo: data['desempleo'] as int? ?? 0,
      religion: data['religion'] as int? ?? 0,
      cultura: data['cultura'] as int? ?? 0,
      impuestosPct: data['impuestosPct'] as int? ?? 0,
      produccionDiaria: Map<String, dynamic>.from(
        data['produccionDiaria'] ?? {},
      ),
      consumoDiario: Map<String, dynamic>.from(data['consumoDiario'] ?? {}),
      edificios: Map<String, dynamic>.from(data['edificios'] ?? {}),
      nivelesTropasDefensaActuales:
          data['nivelesTropasDefensaActuales'] as int? ?? 0,
      nivelesTropasDefensaMinimos:
          data['nivelesTropasDefensaMinimos'] as int? ?? 0,
      totalEdificios: data['totalEdificios'] as int? ?? 0,
    );
  }
}
