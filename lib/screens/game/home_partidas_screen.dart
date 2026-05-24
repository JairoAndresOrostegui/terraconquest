import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/imperio_resumen_model.dart';
import '../../models/partida_model.dart';
import '../../services/partida_service.dart';
import '../admin/partidas/admin_partidas_screen.dart';
import '../admin/terrenos/admin_terrenos_screen.dart';
import 'crear_imperio_screen.dart';
import 'imperio_dashboard_screen.dart';

class HomePartidasScreen extends StatefulWidget {
  const HomePartidasScreen({super.key});

  @override
  State<HomePartidasScreen> createState() => _HomePartidasScreenState();
}

class _HomePartidasScreenState extends State<HomePartidasScreen> {
  final PartidaService _partidaService = PartidaService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  Future<ImperioResumenModel?> _obtenerImperio(String partidaId) async {
    if (_user == null) return null;

    return _partidaService.obtenerImperioDelUsuarioEnPartida(
      partidaId: partidaId,
      userId: _user.uid,
    );
  }

  void _entrarImperio({required String partidaId, required String imperioId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ImperioDashboardScreen(
              partidaId: partidaId,
              imperioId: imperioId,
            ),
      ),
    );
  }

  void _crearImperio(PartidaModel partida) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CrearImperioScreen(partidaId: partida.id),
      ),
    );
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'activa':
        return Colors.green;
      case 'futura':
        return Colors.orange;
      case 'finalizada':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _textoBoton({
    required PartidaModel partida,
    required ImperioResumenModel? imperio,
  }) {
    if (imperio != null) return 'Entrar';
    if (partida.permitirRegistro) return 'Crear imperio';
    return 'Registro cerrado';
  }

  bool _botonHabilitado({
    required PartidaModel partida,
    required ImperioResumenModel? imperio,
  }) {
    if (imperio != null) return true;
    return partida.permitirRegistro;
  }

  void _accionBoton({
    required PartidaModel partida,
    required ImperioResumenModel? imperio,
  }) {
    if (imperio != null) {
      _entrarImperio(partidaId: partida.id, imperioId: imperio.id);
      return;
    }

    if (partida.permitirRegistro) {
      _crearImperio(partida);
    }
  }

  Future<void> _cerrarSesion() {
    return FirebaseAuth.instance.signOut();
  }

  bool _esAdmin(Map<String, dynamic>? usuario) {
    final rol = usuario?['rol']?.toString().trim().toLowerCase();
    return rol == 'admin' || rol == 'administrador';
  }

  Stream<Map<String, dynamic>?> _observarUsuario() {
    final user = _user;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('usuarios')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  void _abrirPartidasAdmin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminPartidasScreen()));
  }

  void _abrirTerrenosAdmin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminTerrenosScreen()));
  }

  Widget _buildNavigation({
    required bool esAdmin,
    required bool mostrarHeader,
  }) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (mostrarHeader)
            const DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Terra Conquest',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Partidas'),
            selected: true,
            onTap: () => Navigator.maybePop(context),
          ),
          if (esAdmin) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Administrar partidas'),
              onTap: () {
                Navigator.maybePop(context);
                _abrirPartidasAdmin();
              },
            ),
            ListTile(
              leading: const Icon(Icons.terrain),
              title: const Text('Administrar terrenos'),
              onTap: () {
                Navigator.maybePop(context);
                _abrirTerrenosAdmin();
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesion'),
            onTap: _cerrarSesion,
          ),
        ],
      ),
    );
  }

  Widget _buildPartidasBody() {
    return StreamBuilder<List<PartidaModel>>(
      stream: _partidaService.observarPartidasDisponibles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('No se pudieron cargar las partidas.'),
          );
        }

        final partidas = snapshot.data ?? [];

        if (partidas.isEmpty) {
          return const Center(
            child: Text('No hay partidas disponibles por ahora.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: partidas.length,
          itemBuilder: (context, index) {
            final partida = partidas[index];

            return FutureBuilder<ImperioResumenModel?>(
              future: _obtenerImperio(partida.id),
              builder: (context, imperioSnapshot) {
                final imperio = imperioSnapshot.data;
                final estadoColor = _colorEstado(partida.estado);
                final textoBoton = _textoBoton(
                  partida: partida,
                  imperio: imperio,
                );
                final habilitado = _botonHabilitado(
                  partida: partida,
                  imperio: imperio,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Semantics(
                      container: true,
                      label:
                          'Partida ${partida.nombre}, estado ${partida.estado}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${partida.nombre} - Ronda ${partida.ronda}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Chip(
                                label: Text(partida.estado),
                                backgroundColor: estadoColor.withValues(
                                  alpha: 0.15,
                                ),
                                labelStyle: TextStyle(
                                  color: estadoColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dia actual: ${partida.diaActual} / ${partida.totalDias}',
                          ),
                          Text(
                            'Maximo imperios por clan: ${partida.maxImperiosPorClan}',
                          ),
                          Text(
                            'Proteccion inicial: ${partida.horasProteccionInicial} horas',
                          ),
                          const SizedBox(height: 8),
                          if (imperioSnapshot.connectionState ==
                              ConnectionState.waiting)
                            const LinearProgressIndicator(),
                          if (imperio != null) ...[
                            Text(
                              'Tu imperio: ${imperio.nombre}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Valor: ${imperio.valor}'),
                            Text('Ranking: ${imperio.ranking}'),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: Semantics(
                              button: true,
                              enabled: habilitado,
                              focusable: true,
                              label: textoBoton,
                              child: FilledButton(
                                onPressed:
                                    habilitado
                                        ? () => _accionBoton(
                                          partida: partida,
                                          imperio: imperio,
                                        )
                                        : null,
                                child: Text(textoBoton),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Debes iniciar sesion para ver las partidas.'),
        ),
      );
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _observarUsuario(),
      builder: (context, usuarioSnapshot) {
        final esAdmin = _esAdmin(usuarioSnapshot.data);

        return LayoutBuilder(
          builder: (context, constraints) {
            final usarMenuLateral = constraints.maxWidth >= 900;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Terra Conquest'),
                automaticallyImplyLeading: !usarMenuLateral,
              ),
              drawer:
                  usarMenuLateral
                      ? null
                      : Drawer(
                        child: _buildNavigation(
                          esAdmin: esAdmin,
                          mostrarHeader: true,
                        ),
                      ),
              body: Row(
                children: [
                  if (usarMenuLateral)
                    SizedBox(
                      width: 280,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        child: _buildNavigation(
                          esAdmin: esAdmin,
                          mostrarHeader: false,
                        ),
                      ),
                    ),
                  Expanded(child: _buildPartidasBody()),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
