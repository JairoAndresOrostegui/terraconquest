class TropaModel {
  const TropaModel({
    required this.id,
    required this.nombre,
    required this.nivel,
    required this.ataque,
    required this.defensa,
    required this.vida,
    required this.costeCompra,
  });

  final String id;
  final String nombre;
  final int nivel;
  final int ataque;
  final int defensa;
  final int vida;
  final Map<String, dynamic> costeCompra;

  factory TropaModel.fromMap(String id, Map<String, dynamic> data) {
    return TropaModel(
      id: id,
      nombre: data['nombre']?.toString() ?? '',
      nivel: (data['nivel'] as num?)?.toInt() ?? 0,
      ataque: (data['ataque'] as num?)?.toInt() ?? 0,
      defensa: (data['defensa'] as num?)?.toInt() ?? 0,
      vida: (data['vida'] as num?)?.toInt() ?? 0,
      costeCompra: Map<String, dynamic>.from(data['costeCompra'] ?? {}),
    );
  }
}
