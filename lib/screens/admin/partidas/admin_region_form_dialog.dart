import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_regiones_service.dart';

class AdminRegionFormDialog extends StatefulWidget {
  const AdminRegionFormDialog({
    super.key,
    required this.partidaId,
    this.region,
  });

  final String partidaId;
  final DocumentSnapshot<Map<String, dynamic>>? region;

  @override
  State<AdminRegionFormDialog> createState() => _AdminRegionFormDialogState();
}

class _AdminRegionFormDialogState extends State<AdminRegionFormDialog> {
  final AdminRegionesService _service = AdminRegionesService();
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _nombreController = TextEditingController();
  final _imagenController = TextEditingController();
  final Set<String> _terrenosSeleccionados = {};

  bool _guardando = false;
  bool _cargandoTerrenos = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _terrenos = [];

  bool get _editando => widget.region != null;

  @override
  void initState() {
    super.initState();

    if (_editando) {
      final data = widget.region!.data() ?? {};
      _numeroController.text = '${data['numero'] ?? 0}';
      _nombreController.text = data['nombre']?.toString() ?? '';
      _imagenController.text = data['imagenMapaUrl']?.toString() ?? '';
      _terrenosSeleccionados.addAll(
        List<String>.from(data['terrenosPermitidos'] ?? []),
      );
    }

    _cargarTerrenos();
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _nombreController.dispose();
    _imagenController.dispose();
    super.dispose();
  }

  Future<void> _cargarTerrenos() async {
    try {
      final terrenos = await _service.obtenerTerrenosActivos();

      if (!mounted) return;

      setState(() {
        _terrenos = terrenos;
        _cargandoTerrenos = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _cargandoTerrenos = false);
      _mensaje('No se pudieron cargar los terrenos.');
    }
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _guardar() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_terrenosSeleccionados.isEmpty) {
      _mensaje('Selecciona al menos un terreno permitido.');
      return;
    }

    setState(() => _guardando = true);

    try {
      await _service.guardarRegion(
        partidaId: widget.partidaId,
        regionId: widget.region?.id,
        numero: int.parse(_numeroController.text.trim()),
        nombre: _nombreController.text,
        terrenosPermitidos: _terrenosSeleccionados.toList(),
        imagenMapaUrl: _imagenController.text,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo guardar la región.');
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Widget _campo({
    required String label,
    required TextEditingController controller,
    bool numerico = false,
    bool requerido = true,
  }) {
    return Semantics(
      textField: true,
      focusable: true,
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: numerico ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (requerido && (value == null || value.trim().isEmpty)) {
            return 'Campo obligatorio';
          }

          if (numerico && int.tryParse(value?.trim() ?? '') == null) {
            return 'Debe ser un número válido';
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildTerrenos() {
    if (_cargandoTerrenos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_terrenos.isEmpty) {
      return const Text('No hay terrenos activos disponibles.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Terrenos permitidos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._terrenos.map((terreno) {
          final data = terreno.data();
          final seleccionado = _terrenosSeleccionados.contains(terreno.id);

          return CheckboxListTile(
            value: seleccionado,
            title: Text(data['nombre']?.toString() ?? terreno.id),
            subtitle: Text(terreno.id),
            onChanged: _guardando
                ? null
                : (value) {
                    setState(() {
                      if (value == true) {
                        _terrenosSeleccionados.add(terreno.id);
                      } else {
                        _terrenosSeleccionados.remove(terreno.id);
                      }
                    });
                  },
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editando ? 'Editar región' : 'Crear región'),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _campo(
                  label: 'Número de región',
                  controller: _numeroController,
                  numerico: true,
                ),
                const SizedBox(height: 12),
                _campo(label: 'Nombre', controller: _nombreController),
                const SizedBox(height: 12),
                _campo(
                  label: 'URL imagen mapa',
                  controller: _imagenController,
                  requerido: false,
                ),
                const SizedBox(height: 16),
                _buildTerrenos(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        Semantics(
          button: true,
          enabled: !_guardando,
          focusable: true,
          label: _editando ? 'Guardar cambios de región' : 'Crear región',
          child: FilledButton(
            onPressed: _guardando ? null : _guardar,
            child: Text(_guardando ? 'Guardando...' : 'Guardar'),
          ),
        ),
      ],
    );
  }
}
