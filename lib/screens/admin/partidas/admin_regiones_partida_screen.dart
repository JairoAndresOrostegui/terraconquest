import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_regiones_service.dart';
import 'admin_region_form_dialog.dart';

class AdminRegionesPartidaScreen extends StatefulWidget {
  const AdminRegionesPartidaScreen({
    super.key,
    required this.partidaId,
    required this.nombrePartida,
  });

  final String partidaId;
  final String nombrePartida;

  @override
  State<AdminRegionesPartidaScreen> createState() =>
      _AdminRegionesPartidaScreenState();
}

class _AdminRegionesPartidaScreenState
    extends State<AdminRegionesPartidaScreen> {
  final AdminRegionesService _service = AdminRegionesService();

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _abrirFormulario({
    DocumentSnapshot<Map<String, dynamic>>? region,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => AdminRegionFormDialog(
        partidaId: widget.partidaId,
        region: region,
      ),
    );

    if (resultado == true && mounted) {
      _mensaje(
        region == null
            ? 'Región creada correctamente.'
            : 'Región actualizada correctamente.',
      );
    }
  }

  Future<void> _confirmarEliminar(
    DocumentSnapshot<Map<String, dynamic>> region,
  ) async {
    final data = region.data() ?? {};

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar región'),
        content: Text(
          'Seguro que deseas eliminar la región "${data['nombre'] ?? ''}"?',
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
      await _service.eliminarRegion(
        partidaId: widget.partidaId,
        regionId: region.id,
      );

      if (!mounted) return;
      _mensaje('Región eliminada correctamente.');
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo eliminar la región.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Regiones - ${widget.nombrePartida}'),
        actions: [
          Semantics(
            button: true,
            enabled: true,
            focusable: true,
            label: 'Crear región',
            child: IconButton(
              tooltip: 'Crear región',
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add_location_alt),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.observarRegiones(widget.partidaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar las regiones.'),
            );
          }

          final regiones = snapshot.data?.docs ?? [];

          if (regiones.isEmpty) {
            return const Center(
              child: Text('Esta partida aún no tiene regiones.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: regiones.length,
            itemBuilder: (context, index) {
              final region = regiones[index];
              final data = region.data();
              final nombre = data['nombre']?.toString() ?? '';
              final terrenos = List<String>.from(
                data['terrenosPermitidos'] ?? [],
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text('${data['numero'] ?? 0} - $nombre'),
                  subtitle: Text(
                    'Terrenos permitidos: ${terrenos.join(', ')}',
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      Semantics(
                        button: true,
                        enabled: true,
                        focusable: true,
                        label: 'Editar región $nombre',
                        child: IconButton(
                          tooltip: 'Editar',
                          onPressed: () => _abrirFormulario(region: region),
                          icon: const Icon(Icons.edit),
                        ),
                      ),
                      Semantics(
                        button: true,
                        enabled: true,
                        focusable: true,
                        label: 'Eliminar región $nombre',
                        child: IconButton(
                          tooltip: 'Eliminar',
                          onPressed: () => _confirmarEliminar(region),
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
