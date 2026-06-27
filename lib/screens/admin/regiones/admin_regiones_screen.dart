import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_regiones_service.dart';
import 'admin_region_global_form_dialog.dart';

class AdminRegionesScreen extends StatefulWidget {
  const AdminRegionesScreen({super.key});

  @override
  State<AdminRegionesScreen> createState() => _AdminRegionesScreenState();
}

class _AdminRegionesScreenState extends State<AdminRegionesScreen> {
  final AdminRegionesService _service = AdminRegionesService();
  static const Map<String, String> _bonosLabels = {
    'produccionPct': 'Produccion global',
    'crecimientoPct': 'Crecimiento',
    'famaPct': 'Fama',
    'ataquePct': 'Ataque',
    'defensaPct': 'Defensa',
    'questHeroePct': 'Quest heroe',
    'heroeAtaquePct': 'Ataque heroes',
    'heroeDefensaPct': 'Defensa heroes',
    'heroeMagiaPct': 'Magia heroes',
    'heroeVidaPct': 'Vida heroes',
    'oroPct': 'Oro',
    'alimentosPct': 'Alimentos',
    'aguaPct': 'Agua',
    'maderaPct': 'Madera',
    'piedraPct': 'Piedra',
    'hierroPct': 'Hierro',
    'herramientasPct': 'Herramientas',
    'armasPct': 'Armas',
    'bloquesPct': 'Bloques',
    'tablasPct': 'Tablas',
    'mithrilPct': 'Mithril',
    'cristalPct': 'Cristal',
    'plataPct': 'Plata',
    'reliquiasPct': 'Reliquias',
    'gemasPct': 'Gemas',
    'joyasPct': 'Joyas',
    'manaPct': 'Mana',
    'karmaPct': 'Karma',
  };

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _abrirFormulario({
    DocumentSnapshot<Map<String, dynamic>>? region,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => AdminRegionGlobalFormDialog(region: region),
    );

    if (resultado == true && mounted) {
      _mensaje(
        region == null
            ? 'Region creada correctamente.'
            : 'Region actualizada correctamente.',
      );
    }
  }

  Future<void> _confirmarEliminar(
    DocumentSnapshot<Map<String, dynamic>> region,
  ) async {
    final data = region.data() ?? {};
    final nombre = data['nombre']?.toString() ?? '';

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar region'),
            content: Text(
              'Seguro que deseas eliminar "$nombre"?\n\n'
              'Si ya fue asignada a partidas, es mejor desactivarla.',
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
      await _service.eliminarRegionGlobal(region.id);
      if (!mounted) return;
      _mensaje('Region eliminada correctamente.');
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo eliminar la region.');
    }
  }

  String _bonosResumen(Map<String, dynamic> bonos) {
    final activos =
        bonos.entries
            .where((entry) => entry.value is num && entry.value != 0)
            .map(
              (entry) =>
                  '${_bonosLabels[entry.key] ?? entry.key}: ${entry.value}%',
            )
            .toList();

    if (activos.isEmpty) return 'Sin bonos';
    return activos.take(6).join(', ');
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
        title: const Text('Administrar regiones'),
        actions: [
          IconButton(
            tooltip: 'Crear region',
            onPressed: () => _abrirFormulario(),
            icon: const Icon(Icons.add_location_alt),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.observarRegionesGlobales(),
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
            return const Center(child: Text('No hay regiones creadas.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: regiones.length,
            itemBuilder: (context, index) {
              final region = regiones[index];
              final data = region.data();
              final nombre = data['nombre']?.toString() ?? '';
              final codigo = data['codigo']?.toString() ?? '';
              final descripcion = data['descripcion']?.toString() ?? '';
              final imagenUrl = data['imagenUrl']?.toString() ?? '';
              final activo = data['activo'] as bool? ?? true;
              final terrenos = List<String>.from(
                data['terrenosPermitidos'] ?? [],
              );
              final bonos = Map<String, dynamic>.from(data['bonos'] ?? {});

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: _buildThumb(
                    imagenUrl: imagenUrl,
                    fallbackIcon: activo ? Icons.map : Icons.block,
                    activo: activo,
                  ),
                  title: Text('$nombre ($codigo)'),
                  subtitle: Text(
                    '$descripcion\n'
                    'Estado: ${activo ? 'Activa' : 'Inactiva'}\n'
                    'Terrenos: ${terrenos.isEmpty ? 'Sin terrenos' : terrenos.join(', ')}\n'
                    'Bonos: ${_bonosResumen(bonos)}',
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _abrirFormulario(region: region),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        onPressed: () => _confirmarEliminar(region),
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
