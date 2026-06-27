import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/firebase_options.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/game/home_partidas_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

const bool _devAutoLogin = bool.fromEnvironment('DEV_AUTO_LOGIN');
const String _devAutoLoginEmail = String.fromEnvironment(
  'DEV_AUTO_LOGIN_EMAIL',
  defaultValue: 'jairoo314@hotmail.com',
);
const String _devAutoLoginPassword = String.fromEnvironment(
  'DEV_AUTO_LOGIN_PASSWORD',
  defaultValue: '123456789',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TerraConquestApp());
}

class TerraConquestApp extends StatelessWidget {
  const TerraConquestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Terra Conquest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const _AuthGate(),
      routes: {
        AdminDashboardScreen.routeName: (_) => const AdminDashboardScreen(),
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final AuthService _authService = AuthService();
  bool _autoLoginIntentado = false;

  Future<void> _intentarAutoLogin(User? user) async {
    if (!_devAutoLogin || _autoLoginIntentado || user != null) return;

    _autoLoginIntentado = true;
    try {
      await _authService.iniciarSesion(
        correo: _devAutoLoginEmail,
        password: _devAutoLoginPassword,
      );
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = snapshot.data;
        if (user != null) return const HomePartidasScreen();

        if (_devAutoLogin && !_autoLoginIntentado) {
          _intentarAutoLogin(user);
          return const SplashScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Terra Conquest',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.orange),
          ],
        ),
      ),
    );
  }
}
