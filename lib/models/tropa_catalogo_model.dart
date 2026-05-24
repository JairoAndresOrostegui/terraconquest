import 'package:cloud_firestore/cloud_firestore.dart';

class TropaCatalogoModel {
  const TropaCatalogoModel({
    required this.id,
    required this.razaId,
    required this.nivel,
    required this.nombre,
    required this.descripcion,
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
    required this.costeCompra,
    required this.mantenimiento,
    required this.desbloqueo,
    required this.activo,
  });

  final String id;
  final String razaId;
  final int nivel;
  final String nombre;
  final String descripcion;
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
  final Map<String, dynamic> costeCompra;
  final Map<String, dynamic> mantenimiento;
  final Map<String, dynamic> desbloqueo;
  final bool activo;

  factory TropaCatalogoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TropaCatalogoModel(
      id: doc.id,
      razaId: data['razaId']?.toString() ?? '',
      nivel: (data['nivel'] as num?)?.toInt() ?? 0,
      nombre: data['nombre']?.toString() ?? '',
      descripcion: data['descripcion']?.toString() ?? '',
      ataque: (data['ataque'] as num?)?.toInt() ?? 0,
      defensa: (data['defensa'] as num?)?.toInt() ?? 0,
      danio: (data['danio'] as num?)?.toInt() ?? 0,
      vida: (data['vida'] as num?)?.toInt() ?? 0,
      velocidad: (data['velocidad'] as num?)?.toInt() ?? 0,
      moral: (data['moral'] as num?)?.toInt() ?? 0,
      tipoAtaque: data['tipoAtaque']?.toString() ?? '',
      tipoDefensa: data['tipoDefensa']?.toString() ?? '',
      tipoMagia: data['tipoMagia']?.toString() ?? '',
      habilidades: List<String>.from(data['habilidades'] ?? const []),
      costeCompra: Map<String, dynamic>.from(data['costeCompra'] ?? {}),
      mantenimiento: Map<String, dynamic>.from(data['mantenimiento'] ?? {}),
      desbloqueo: Map<String, dynamic>.from(data['desbloqueo'] ?? {}),
      activo: data['activo'] as bool? ?? true,
    );
  }
}
