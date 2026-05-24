import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_terrenos_service.dart';
import 'admin_terreno_form_dialog.dart';

class AdminTerrenosScreen extends StatefulWidget {
  const AdminTerrenosScreen({super.key});

  @override
  State<AdminTerrenosScreen> createState() => _AdminTerrenosScreenState();
}

class _AdminTerrenosScreenState extends State<AdminTerrenosScreen> {
  final AdminTerrenosService _service = AdminTerrenosService();

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _abrirFormulario({
    DocumentSnapshot<Map<String, dynamic>>? terreno,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => AdminTerrenoFormDialog(terreno: terreno),
    );

    if (resultado == true && mounted) {
      _mensaje(
        terreno == null
            ? 'Terreno creado correctamente.'
            : 'Terreno actualizado correctamente.',
      );
    }
  }

  Future<void> _confirmarEliminar(
    DocumentSnapshot<Map<String, dynamic>> terreno,
  ) async {
    final data = terreno.data() ?? {};
    final nombre = data['nombre']?.toString() ?? '';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar terreno'),
        content: Text(
          'Seguro que deseas eliminar "$nombre"?\n\n'
          'Nota: si este terreno ya está usado por regiones o ciudades, es mejor desactivarlo en lugar de eliminarlo.',
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
      await _service.eliminarTerreno(terreno.id);
      if (!mounted) return;
      _mensaje('Terreno eliminado correctamente.');
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo eliminar el terreno.');
    }
  }

  String _bonosResumen(Map<String, dynamic> bonos) {
    final activos = bonos.entries
        .where((entry) => entry.value is num && entry.value != 0)
        .map((entry) => '${entry.key}: ${entry.value}%')
        .toList();

    if (activos.isEmpty) return 'Sin bonos';

    return activos.take(6).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar terrenos'),
        actions: [
          Semantics(
            button: true,
            enabled: true,
            focusable: true,
            label: 'Crear terreno',
            child: IconButton(
              tooltip: 'Crear terreno',
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.observarTerrenos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar los terrenos.'),
            );
          }

          final terrenos = snapshot.data?.docs ?? [];

          if (terrenos.isEmpty) {
            return const Center(child: Text('No hay terrenos creados.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: terrenos.length,
            itemBuilder: (context, index) {
              final terreno = terrenos[index];
              final data = terreno.data();
              final nombre = data['nombre']?.toString() ?? '';
              final codigo = data['codigo']?.toString() ?? '';
              final descripcion = data['descripcion']?.toString() ?? '';
              final activo = data['activo'] as bool? ?? true;
              final bonos = Map<String, dynamic>.from(data['bonos'] ?? {});

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(activo ? Icons.terrain : Icons.block),
                  title: Text('$nombre ($codigo)'),
                  subtitle: Text(
                    '$descripcion\n'
                    'Estado: ${activo ? 'Activo' : 'Inactivo'}\n'
                    'Bonos: ${_bonosResumen(bonos)}',
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      Semantics(
                        button: true,
                        enabled: true,
                        focusable: true,
                        label: 'Editar terreno $nombre',
                        child: IconButton(
                          tooltip: 'Editar',
                          onPressed: () => _abrirFormulario(terreno: terreno),
                          icon: const Icon(Icons.edit),
                        ),
                      ),
                      Semantics(
                        button: true,
                        enabled: true,
                        focusable: true,
                        label: 'Eliminar terreno $nombre',
                        child: IconButton(
                          tooltip: 'Eliminar',
                          onPressed: () => _confirmarEliminar(terreno),
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
