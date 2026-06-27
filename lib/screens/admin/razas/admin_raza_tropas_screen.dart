import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_razas_service.dart';
import 'admin_raza_tropa_form_dialog.dart';

class AdminRazaTropasScreen extends StatefulWidget {
  const AdminRazaTropasScreen({
    super.key,
    required this.razaId,
    required this.nombreRaza,
  });

  final String razaId;
  final String nombreRaza;

  @override
  State<AdminRazaTropasScreen> createState() => _AdminRazaTropasScreenState();
}

class _AdminRazaTropasScreenState extends State<AdminRazaTropasScreen> {
  final AdminRazasService _service = AdminRazasService();

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _abrirFormulario({
    DocumentSnapshot<Map<String, dynamic>>? tropa,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder:
          (_) => AdminRazaTropaFormDialog(razaId: widget.razaId, tropa: tropa),
    );

    if (resultado == true && mounted) {
      _mensaje('Tropa guardada correctamente.');
    }
  }

  Future<void> _eliminar(DocumentSnapshot<Map<String, dynamic>> tropa) async {
    try {
      await _service.eliminarTropa(razaId: widget.razaId, tropaId: tropa.id);
      if (!mounted) return;
      _mensaje('Tropa eliminada correctamente.');
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo eliminar la tropa.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tropas - ${widget.nombreRaza}'),
        actions: [
          IconButton(
            tooltip: 'Crear tropa',
            onPressed: () => _abrirFormulario(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.observarTropas(widget.razaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tropas = [...snapshot.data?.docs ?? []];
          tropas.sort((a, b) {
            final nivelA = (a.data()['nivel'] as num?)?.toInt() ?? 0;
            final nivelB = (b.data()['nivel'] as num?)?.toInt() ?? 0;
            return nivelA.compareTo(nivelB);
          });
          if (tropas.isEmpty) {
            return const Center(child: Text('No hay tropas creadas.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tropas.length,
            itemBuilder: (context, index) {
              final tropa = tropas[index];
              final data = tropa.data();
              final nombre = data['nombre']?.toString() ?? tropa.id;
              final activo = data['activo'] as bool? ?? true;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(activo ? Icons.shield : Icons.block),
                  title: Text('$nombre (${data['codigo'] ?? tropa.id})'),
                  subtitle: Text(
                    'Nivel ${data['nivel'] ?? 0} | Ataque ${data['ataque'] ?? 0} | Defensa ${data['defensa'] ?? 0} | Vida ${data['vida'] ?? 0}\n'
                    '${data['descripcion'] ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _abrirFormulario(tropa: tropa),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        onPressed: () => _eliminar(tropa),
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
