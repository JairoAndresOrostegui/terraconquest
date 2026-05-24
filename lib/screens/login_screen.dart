import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'game/home_partidas_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _registrando = false;
  bool _cargando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _cargando = true);

    try {
      if (_registrando) {
        await _authService.registrar(
          nombreUsuario: _nombreController.text,
          correo: _correoController.text,
          password: _passwordController.text,
        );
      } else {
        await _authService.iniciarSesion(
          correo: _correoController.text,
          password: _passwordController.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePartidasScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mensajeError(error))),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _mensajeError(Object error) {
    final texto = error.toString();
    if (texto.contains('invalid-credential')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (texto.contains('email-already-in-use')) {
      return 'Ese correo ya está registrado.';
    }
    if (texto.contains('weak-password')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return 'No fue posible completar la autenticación.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terra Conquest')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                if (_registrando)
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre de usuario'),
                    validator: (value) {
                      if (!_registrando) return null;
                      return value == null || value.trim().isEmpty
                          ? 'Ingresa tu nombre de usuario.'
                          : null;
                    },
                  ),
                TextFormField(
                  controller: _correoController,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Ingresa tu correo.' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (value) =>
                      value == null || value.length < 6 ? 'Mínimo 6 caracteres.' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _cargando ? null : _enviar,
                  child: Text(_registrando ? 'Crear cuenta' : 'Iniciar sesión'),
                ),
                TextButton(
                  onPressed: _cargando
                      ? null
                      : () => setState(() => _registrando = !_registrando),
                  child: Text(
                    _registrando
                        ? 'Ya tengo cuenta'
                        : 'Crear una cuenta nueva',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
