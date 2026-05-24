import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_terrenos_service.dart';

class AdminTerrenoFormDialog extends StatefulWidget {
  const AdminTerrenoFormDialog({super.key, this.terreno});

  final DocumentSnapshot<Map<String, dynamic>>? terreno;

  @override
  State<AdminTerrenoFormDialog> createState() =>
      _AdminTerrenoFormDialogState();
}

class _AdminTerrenoFormDialogState extends State<AdminTerrenoFormDialog> {
  final AdminTerrenosService _service = AdminTerrenosService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _imagenController = TextEditingController();

  final Map<String, TextEditingController> _bonosControllers = {};

  final List<String> _bonosKeys = const [
    'ataquePct',
    'defensaPct',
    'crecimientoPct',
    'oroPct',
    'alimentosPct',
    'aguaPct',
    'maderaPct',
    'piedraPct',
    'hierroPct',
    'herramientasPct',
    'armasPct',
    'bloquesPct',
    'tablasPct',
    'mithrilPct',
    'cristalPct',
    'plataPct',
    'reliquiasPct',
    'gemasPct',
    'joyasPct',
  ];

  bool _activo = true;
  bool _guardando = false;

  bool get _editando => widget.terreno != null;

  @override
  void initState() {
    super.initState();

    for (final key in _bonosKeys) {
      _bonosControllers[key] = TextEditingController(text: '0');
    }

    if (_editando) {
      final data = widget.terreno!.data() ?? {};
      final bonos = Map<String, dynamic>.from(data['bonos'] ?? {});

      _nombreController.text = data['nombre']?.toString() ?? '';
      _codigoController.text = data['codigo']?.toString() ?? '';
      _descripcionController.text = data['descripcion']?.toString() ?? '';
      _imagenController.text = data['imagenUrl']?.toString() ?? '';
      _activo = data['activo'] as bool? ?? true;

      for (final key in _bonosKeys) {
        _bonosControllers[key]!.text = '${bonos[key] ?? 0}';
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _descripcionController.dispose();
    _imagenController.dispose();

    for (final controller in _bonosControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Map<String, int> _obtenerBonos() {
    final bonos = <String, int>{};

    for (final key in _bonosKeys) {
      bonos[key] = int.tryParse(_bonosControllers[key]!.text.trim()) ?? 0;
    }

    return bonos;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
    });

    try {
      await _service.guardarTerreno(
        terrenoId: widget.terreno?.id,
        nombre: _nombreController.text,
        codigo: _codigoController.text,
        descripcion: _descripcionController.text,
        imagenUrl: _imagenController.text,
        activo: _activo,
        bonos: _obtenerBonos(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo guardar el terreno.');
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
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

          if (numerico && int.tryParse(value!.trim()) == null) {
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

  String _labelBono(String key) {
    return key
        .replaceAll('Pct', ' %')
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim();
  }

  Widget _buildBonos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bonos del terreno',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columnas = constraints.maxWidth > 720 ? 3 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bonosKeys.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnas,
                childAspectRatio: 3.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final key = _bonosKeys[index];

                return _campo(
                  label: _labelBono(key),
                  controller: _bonosControllers[key]!,
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
      title: Text(_editando ? 'Editar terreno' : 'Crear terreno'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _campo(label: 'Nombre', controller: _nombreController),
                const SizedBox(height: 12),
                _campo(label: 'Código', controller: _codigoController),
                const SizedBox(height: 12),
                _campo(
                  label: 'Descripción',
                  controller: _descripcionController,
                ),
                const SizedBox(height: 12),
                _campo(
                  label: 'URL imagen',
                  controller: _imagenController,
                  requerido: false,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Activo'),
                  value: _activo,
                  onChanged: _guardando
                      ? null
                      : (value) => setState(() => _activo = value),
                ),
                const SizedBox(height: 16),
                _buildBonos(),
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
          label: _editando ? 'Guardar cambios de terreno' : 'Crear terreno',
          child: FilledButton(
            onPressed: _guardando ? null : _guardar,
            child: Text(_guardando ? 'Guardando...' : 'Guardar'),
          ),
        ),
      ],
    );
  }
}
