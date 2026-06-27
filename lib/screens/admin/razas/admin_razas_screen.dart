import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_razas_service.dart';
import 'admin_raza_form_dialog.dart';
import 'admin_raza_politicas_screen.dart';
import 'admin_raza_tropas_screen.dart';

class AdminRazasScreen extends StatefulWidget {
  const AdminRazasScreen({super.key});

  @override
  State<AdminRazasScreen> createState() => _AdminRazasScreenState();
}

class _AdminRazasScreenState extends State<AdminRazasScreen> {
  final AdminRazasService _service = AdminRazasService();

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _abrirFormulario({
    DocumentSnapshot<Map<String, dynamic>>? raza,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => AdminRazaFormDialog(raza: raza),
    );

    if (resultado == true && mounted) {
      _mensaje(
        raza == null
            ? 'Raza creada correctamente.'
            : 'Raza actualizada correctamente.',
      );
    }
  }

  Future<void> _confirmarEliminar(
    DocumentSnapshot<Map<String, dynamic>> raza,
  ) async {
    final data = raza.data() ?? {};
    final nombre = data['nombre']?.toString() ?? raza.id;

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar raza'),
            content: Text(
              'Seguro que deseas eliminar "$nombre"?\n\n'
              'Si ya hay imperios o tropas usando esta raza, es mejor desactivarla.',
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
      await _service.eliminarRaza(raza.id);
      if (!mounted) return;
      _mensaje('Raza eliminada correctamente.');
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo eliminar la raza.');
    }
  }

  void _abrirPoliticas({required String razaId, required String nombre}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AdminRazaPoliticasScreen(razaId: razaId, nombreRaza: nombre),
      ),
    );
  }

  void _abrirTropas({required String razaId, required String nombre}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AdminRazaTropasScreen(razaId: razaId, nombreRaza: nombre),
      ),
    );
  }

  String _resumenMapa(Map<String, dynamic> data) {
    final activos =
        data.entries
            .where((entry) => entry.value is num && entry.value != 0)
            .map((entry) => '${entry.key}: ${entry.value}%')
            .toList();

    if (activos.isEmpty) return 'Sin valores';
    return activos.take(5).join(', ');
  }

  Widget _buildThumb({
    required String imagenUrl,
    required IconData fallbackIcon,
    required bool activo,
  }) {
    final url = imagenUrl.trim();

    return Opacity(
      opacity: activo ? 1 : 0.55,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 64,
          height: 64,
          child:
              url.isEmpty
                  ? ColoredBox(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(fallbackIcon),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar razas'),
        actions: [
          IconButton(
            tooltip: 'Crear raza',
            onPressed: () => _abrirFormulario(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.observarRazas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar las razas.'),
            );
          }

          final razas = snapshot.data?.docs ?? [];

          if (razas.isEmpty) {
            return const Center(child: Text('No hay razas creadas.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: razas.length,
            itemBuilder: (context, index) {
              final raza = razas[index];
              final data = raza.data();
              final nombre = data['nombre']?.toString() ?? raza.id;
              final codigo = data['codigo']?.toString() ?? raza.id;
              final descripcion = data['descripcion']?.toString() ?? '';
              final imagenUrl = data['imagenUrl']?.toString() ?? '';
              final activo = data['activo'] as bool? ?? true;
              final bonos = Map<String, dynamic>.from(data['bonos'] ?? {});
              final penalizaciones = Map<String, dynamic>.from(
                data['penalizaciones'] ?? {},
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: _buildThumb(
                    imagenUrl: imagenUrl,
                    fallbackIcon: activo ? Icons.diversity_3 : Icons.block,
                    activo: activo,
                  ),
                  title: Text('$nombre ($codigo)'),
                  subtitle: Text(
                    '$descripcion\n'
                    'Estado: ${activo ? 'Activa' : 'Inactiva'}\n'
                    'Bonos: ${_resumenMapa(bonos)}\n'
                    'Penalizaciones: ${_resumenMapa(penalizaciones)}',
                  ),
                  isThreeLine: false,
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Politicas',
                        onPressed:
                            () => _abrirPoliticas(
                              razaId: raza.id,
                              nombre: nombre,
                            ),
                        icon: const Icon(Icons.policy),
                      ),
                      IconButton(
                        tooltip: 'Tropas',
                        onPressed:
                            () => _abrirTropas(razaId: raza.id, nombre: nombre),
                        icon: const Icon(Icons.shield),
                      ),
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _abrirFormulario(raza: raza),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        onPressed: () => _confirmarEliminar(raza),
                        icon: const Icon(Icons.delete),
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
