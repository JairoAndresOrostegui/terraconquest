import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_partidas_crud_service.dart';
import 'admin_partida_form_dialog.dart';

class AdminPartidasScreen extends StatefulWidget {
  const AdminPartidasScreen({super.key});

  @override
  State<AdminPartidasScreen> createState() => _AdminPartidasScreenState();
}

class _AdminPartidasScreenState extends State<AdminPartidasScreen> {
  final AdminPartidasCrudService _service = AdminPartidasCrudService();

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _abrirFormulario({
    DocumentSnapshot<Map<String, dynamic>>? partida,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => AdminPartidaFormDialog(partida: partida),
    );

    if (resultado == true && mounted) {
      _mostrarMensaje(
        partida == null
            ? 'Partida creada correctamente.'
            : 'Partida actualizada correctamente.',
      );
    }
  }

  Future<void> _confirmarEliminar(
    DocumentSnapshot<Map<String, dynamic>> partida,
  ) async {
    final data = partida.data() ?? {};
    final estado = data['estado']?.toString() ?? '';

    if (estado == 'activa') {
      _mostrarMensaje(
        'No se puede eliminar una partida activa. Cámbiala a finalizada o futura primero.',
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar partida'),
            content: Text(
              'Seguro que deseas eliminar "${data['nombre'] ?? 'esta partida'}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    try {
      await _service.eliminarPartida(partida.id);
      if (!mounted) return;
      _mostrarMensaje('Partida eliminada correctamente.');
    } catch (_) {
      if (!mounted) return;
      _mostrarMensaje('No se pudo eliminar la partida.');
    }
  }

  String _fecha(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      final mes = date.month.toString().padLeft(2, '0');
      final dia = date.day.toString().padLeft(2, '0');
      return '${date.year}-$mes-$dia';
    }
    return 'Sin fecha';
  }

  Widget _buildMapaThumb(String imagenUrl) {
    final url = imagenUrl.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child:
            url.isEmpty
                ? ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.map),
                )
                : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => ColoredBox(
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image),
                      ),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar partidas'),
        actions: [
          Semantics(
            button: true,
            enabled: true,
            focusable: true,
            label: 'Crear nueva partida',
            child: IconButton(
              tooltip: 'Crear partida',
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.observarPartidas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar las partidas.'),
            );
          }

          final partidas = snapshot.data?.docs ?? [];

          if (partidas.isEmpty) {
            return const Center(child: Text('No hay partidas creadas.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: partidas.length,
            itemBuilder: (context, index) {
              final partida = partidas[index];
              final data = partida.data();
              final nombre = data['nombre']?.toString() ?? '';
              final regiones = List<String>.from(
                data['regionesDisponibles'] ?? [],
              );
              final imagenMapaUrl = data['imagenMapaUrl']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text('$nombre - Ronda ${data['ronda'] ?? 0}'),
                  subtitle: Text(
                    'Estado: ${data['estado'] ?? ''}\n'
                    'Inicio: ${_fecha(data['fechaInicio'])} | Fin: ${_fecha(data['fechaFin'])}\n'
                    'Día: ${data['diaActual'] ?? 0}/${data['totalDias'] ?? 0} | Registro: ${(data['permitirRegistro'] ?? false) ? 'abierto' : 'cerrado'}\n'
                    'Protección: inicial ${data['horasProteccionInicial'] ?? 0}h | ataque ${data['horasProteccionAtaque'] ?? 0}h',
                  ),
                  isThreeLine: false,
                  leading: Badge(
                    label: Text(regiones.length.toString()),
                    child: _buildMapaThumb(imagenMapaUrl),
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      Semantics(
                        button: true,
                        enabled: true,
                        focusable: true,
                        label: 'Editar partida $nombre',
                        child: IconButton(
                          tooltip: 'Editar',
                          onPressed: () => _abrirFormulario(partida: partida),
                          icon: const Icon(Icons.edit),
                        ),
                      ),
                      Semantics(
                        button: true,
                        enabled: true,
                        focusable: true,
                        label: 'Eliminar partida $nombre',
                        child: IconButton(
                          tooltip: 'Eliminar',
                          onPressed: () => _confirmarEliminar(partida),
                          icon: const Icon(Icons.delete),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
