enum UsuarioRol {
  jugador('jugador'),
  admin('admin');

  const UsuarioRol(this.value);
  final String value;
}

enum UsuarioEstado {
  activo('activo'),
  bloqueado('bloqueado');

  const UsuarioEstado(this.value);
  final String value;
}

enum PartidaEstado {
  futura('futura'),
  activa('activa'),
  finalizada('finalizada');

  const PartidaEstado(this.value);
  final String value;
}

enum ImperioEstado {
  activo('activo'),
  eliminado('eliminado'),
  bloqueado('bloqueado');

  const ImperioEstado(this.value);
  final String value;
}

enum CiudadEstado {
  activa('activa'),
  conquistada('conquistada'),
  destruida('destruida');

  const CiudadEstado(this.value);
  final String value;
}

enum HeroeClase {
  guerrero('guerrero'),
  ladron('ladron'),
  mago('mago'),
  sacerdote('sacerdote');

  const HeroeClase(this.value);
  final String value;
}

enum HeroeEstado {
  activo('activo'),
  capturado('capturado'),
  muerto('muerto');

  const HeroeEstado(this.value);
  final String value;
}

enum ClanTipoIngreso {
  abierto('abierto'),
  privado('privado');

  const ClanTipoIngreso(this.value);
  final String value;
}

enum ClanEstado {
  activo('activo'),
  disuelto('disuelto');

  const ClanEstado(this.value);
  final String value;
}

T enumFromValue<T extends Enum>(
  List<T> values,
  String? value,
  T fallback,
  String Function(T item) wireValue,
) {
  for (final item in values) {
    if (wireValue(item) == value) return item;
  }
  return fallback;
}
