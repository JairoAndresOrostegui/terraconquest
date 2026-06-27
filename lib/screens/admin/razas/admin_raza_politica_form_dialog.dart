import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_razas_service.dart';

class AdminRazaPoliticaFormDialog extends StatefulWidget {
  const AdminRazaPoliticaFormDialog({
    super.key,
    required this.razaId,
    this.politica,
  });

  final String razaId;
  final DocumentSnapshot<Map<String, dynamic>>? politica;

  @override
  State<AdminRazaPoliticaFormDialog> createState() =>
      _AdminRazaPoliticaFormDialogState();
}

class _AdminRazaPoliticaFormDialogState
    extends State<AdminRazaPoliticaFormDialog> {
  final AdminRazasService _service = AdminRazasService();
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final Map<String, TextEditingController> _bonosControllers = {};
  final Map<String, TextEditingController> _penalizacionesControllers = {};

  static const _valores = {
    'produccionPct': 'Produccion',
    'crecimientoPct': 'Crecimiento',
    'ataquePct': 'Ataque',
    'defensaPct': 'Defensa',
    'comercioPct': 'Comercio',
    'magiaPct': 'Magia',
  };

  bool _activo = true;
  bool _guardando = false;

  bool get _editando => widget.politica != null;

  @override
  void initState() {
    super.initState();

    for (final key in _valores.keys) {
      _bonosControllers[key] = TextEditingController(text: '0');
      _penalizacionesControllers[key] = TextEditingController(text: '0');
    }

    if (_editando) {
      final data = widget.politica!.data() ?? {};
      final bonos = Map<String, dynamic>.from(data['bonos'] ?? {});
      final penalizaciones = Map<String, dynamic>.from(
        data['penalizaciones'] ?? {},
      );

      _codigoController.text =
          data['codigo']?.toString() ?? widget.politica!.id;
      _nombreController.text = data['nombre']?.toString() ?? '';
      _descripcionController.text = data['descripcion']?.toString() ?? '';
      _activo = data['activo'] as bool? ?? true;

      for (final key in _valores.keys) {
        _bonosControllers[key]!.text = '${bonos[key] ?? 0}';
        _penalizacionesControllers[key]!.text = '${penalizaciones[key] ?? 0}';
      }
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    for (final controller in _bonosControllers.values) {
      controller.dispose();
    }
    for (final controller in _penalizacionesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _codigo(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_ -]'), '')
        .replaceAll(RegExp(r'[\s-]+'), '_');
  }

  Map<String, int> _mapa(Map<String, TextEditingController> controllers) {
    return {
      for (final key in _valores.keys)
        key: int.tryParse(controllers[key]!.text.trim()) ?? 0,
    };
  }

  Future<void> _guardar() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _guardando = true);
    try {
      await _service.guardarPolitica(
        razaId: widget.razaId,
        politicaIdActual: widget.politica?.id,
        codigo: _codigo(_codigoController.text),
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        activo: _activo,
        bonos: _mapa(_bonosControllers),
        penalizaciones: _mapa(_penalizacionesControllers),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la politica.')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _campo({
    required String label,
    required TextEditingController controller,
    bool numerico = false,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled && !_guardando,
      maxLines: maxLines,
      keyboardType: numerico ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
        if (numerico && int.tryParse(value.trim()) == null) {
          return 'Debe ser un numero valido';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildMapaValores({
    required String titulo,
    required Map<String, TextEditingController> controllers,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columnas = constraints.maxWidth > 720 ? 3 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _valores.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnas,
                childAspectRatio: 3.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final key = _valores.keys.elementAt(index);
                return _campo(
                  label: '${_valores[key]} (%)',
                  controller: controllers[key]!,
                  numerico: true,
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editando ? 'Editar politica' : 'Crear politica'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _campo(
                  label: 'Codigo',
                  controller: _codigoController,
                  enabled: !_editando,
                ),
                const SizedBox(height: 12),
                _campo(label: 'Nombre', controller: _nombreController),
                const SizedBox(height: 12),
                _campo(
                  label: 'Descripcion',
                  controller: _descripcionController,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Activa'),
                  value: _activo,
                  onChanged:
                      _guardando
                          ? null
                          : (value) => setState(() => _activo = value),
                ),
                const SizedBox(height: 16),
                _buildMapaValores(
                  titulo: 'Bonos',
                  controllers: _bonosControllers,
                ),
                const SizedBox(height: 16),
                _buildMapaValores(
                  titulo: 'Penalizaciones',
                  controllers: _penalizacionesControllers,
                ),
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
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: Text(_guardando ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}
