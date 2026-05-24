import 'model_helpers.dart';
import 'model_types.dart';

class UsuarioModel {
  const UsuarioModel({
    this.id,
    required this.uid,
    required this.nombreUsuario,
    required this.correo,
    required this.rol,
    required this.estado,
    required this.rubies,
    this.creadoEn,
    this.actualizadoEn,
    this.ultimoLogin,
  });

  final String? id;
  final String uid;
  final String nombreUsuario;
  final String correo;
  final UsuarioRol rol;
  final UsuarioEstado estado;
  final int rubies;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;
  final DateTime? ultimoLogin;

  factory UsuarioModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return UsuarioModel(
      id: id,
      uid: stringFromValue(map['uid'], fallback: id ?? ''),
      nombreUsuario: stringFromValue(map['nombreUsuario']),
      correo: stringFromValue(map['correo']),
      rol: enumFromValue(
        UsuarioRol.values,
        map['rol'] as String?,
        UsuarioRol.jugador,
        (item) => item.value,
      ),
      estado: enumFromValue(
        UsuarioEstado.values,
        map['estado'] as String?,
        UsuarioEstado.activo,
        (item) => item.value,
      ),
      rubies: intFromValue(map['rubies']),
      creadoEn: dateFromValue(map['creadoEn']),
      actualizadoEn: dateFromValue(map['actualizadoEn']),
      ultimoLogin: dateFromValue(map['ultimoLogin']),
    );
  }

  Map<String, dynamic> toMap() {
    return cleanMap({
      'uid': uid,
      'nombreUsuario': nombreUsuario,
      'correo': correo,
      'rol': rol.value,
      'estado': estado.value,
      'rubies': rubies,
      'creadoEn': creadoEn,
      'actualizadoEn': actualizadoEn,
      'ultimoLogin': ultimoLogin,
    });
  }
}
