import 'package:cloud_firestore/cloud_firestore.dart';

class TropaCiudadModel {
  const TropaCiudadModel({
    required this.id,
    required this.tropaId,
    required this.razaId,
    required this.nivel,
    required this.nombre,
    required this.cantidad,
    required this.ataque,
    required this.defensa,
    required this.danio,
    required this.vida,
    required this.velocidad,
    required this.moral,
    required this.tipoAtaque,
    required this.tipoDefensa,
    required this.tipoMagia,
    required this.habilidades,
    required this.asignacion,
    required this.actualizadoEn,
  });

  final String id;
  final String tropaId;
  final String razaId;
  final int nivel;
  final String nombre;
  final int cantidad;
  final int ataque;
  final int defensa;
  final int danio;
  final int vida;
  final int velocidad;
  final int moral;
  final String tipoAtaque;
  final String tipoDefensa;
  final String tipoMagia;
  final List<String> habilidades;
  final String asignacion;
  final DateTime? actualizadoEn;

  int get nivelesTotales => cantidad * nivel;

  factory TropaCiudadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TropaCiudadModel(
      id: doc.id,
      tropaId: data['tropaId']?.toString() ?? doc.id,
      razaId: data['razaId']?.toString() ?? '',
      nivel: (data['nivel'] as num?)?.toInt() ?? 0,
      nombre: data['nombre']?.toString() ?? '',
      cantidad: (data['cantidad'] as num?)?.toInt() ?? 0,
      ataque: (data['ataque'] as num?)?.toInt() ?? 0,
      defensa: (data['defensa'] as num?)?.toInt() ?? 0,
      danio: (data['danio'] as num?)?.toInt() ?? 0,
      vida: (data['vida'] as num?)?.toInt() ?? 0,
      velocidad: (data['velocidad'] as num?)?.toInt() ?? 0,
      moral: (data['moral'] as num?)?.toInt() ?? 0,
      tipoAtaque: data['tipoAtaque']?.toString() ?? 'fisico',
      tipoDefensa: data['tipoDefensa']?.toString() ?? 'normal',
      tipoMagia: data['tipoMagia']?.toString() ?? 'ninguno',
      habilidades: List<String>.from(data['habilidades'] ?? const []),
      asignacion: data['asignacion']?.toString() ?? 'reserva',
      actualizadoEn: (data['actualizadoEn'] as Timestamp?)?.toDate(),
    );
  }
}
