import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: correo.trim(),
      password: password,
    );
    await _actualizarUltimoLogin();
  }

  Future<void> registrar({
    required String nombreUsuario,
    required String correo,
    required String password,
  }) async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: correo.trim(),
      password: password,
    );

    final uid = credencial.user!.uid;
    final ahora = FieldValue.serverTimestamp();

    await _firestore.collection('usuarios').doc(uid).set({
      'uid': uid,
      'nombreUsuario': nombreUsuario.trim(),
      'correo': correo.trim(),
      'rol': 'jugador',
      'estado': 'activo',
      'rubies': 0,
      'creadoEn': ahora,
      'actualizadoEn': ahora,
      'ultimoLogin': ahora,
    });
  }

  Future<void> cerrarSesion() {
    return _auth.signOut();
  }

  Future<void> _actualizarUltimoLogin() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('usuarios').doc(user.uid).set({
      'uid': user.uid,
      'correo': user.email ?? '',
      'ultimoLogin': FieldValue.serverTimestamp(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
