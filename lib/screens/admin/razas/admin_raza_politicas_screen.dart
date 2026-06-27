import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_razas_service.dart';
import 'admin_raza_politica_form_dialog.dart';

class AdminRazaPoliticasScreen extends StatefulWidget {
  const AdminRazaPoliticasScreen({
    super.key,
    required this.razaId,
    required this.nombreRaza,
  });

  final String razaId;
  final String nombreRaza;

  @override
  State<AdminRazaPoliticasScreen> createState() =>
      _AdminRazaPoliticasScreenState();
}

class _AdminRazaPoliticasScreenState extends State<AdminRazaPoliticasScreen> {
  final AdminRazasService _service = AdminRazasService();

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _abrirFormulario({
    DocumentSnapshot<Map<String, dynamic>>? politica,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder:
          (_) => AdminRazaPoliticaFormDialog(
            razaId: widget.razaId,
            politica: politica,
          ),
    );

    if (resultado == true && mounted) {
      _mensaje('Politica guardada correctamente.');
    }
  }

  Future<void> _eliminar(
    DocumentSnapshot<Map<String, dynamic>> politica,
  ) async {
    try {
      await _service.eliminarPolitica(
        razaId: widget.razaId,
        politicaId: politica.id,
      );
      if (!mounted) return;
      _mensaje('Politica eliminada correctamente.');
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo eliminar la politica.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Politicas - ${widget.nombreRaza}'),
        actions: [
          IconButton(
            tooltip: 'Crear politica',
            onPressed: () => _abrirFormulario(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.observarPoliticas(widget.razaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final politicas = snapshot.data?.docs ?? [];
          if (politicas.isEmpty) {
            return const Center(child: Text('No hay politicas creadas.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: politicas.length,
            itemBuilder: (context, index) {
              final politica = politicas[index];
              final data = politica.data();
              final nombre = data['nombre']?.toString() ?? politica.id;
              final activo = data['activo'] as bool? ?? true;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(activo ? Icons.policy : Icons.block),
                  title: Text('$nombre (${data['codigo'] ?? politica.id})'),
                  subtitle: Text(data['descripcion']?.toString() ?? ''),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _abrirFormulario(politica: politica),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        onPressed: () => _eliminar(politica),
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
