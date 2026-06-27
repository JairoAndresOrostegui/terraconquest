import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_razas_service.dart';

class AdminRazaFormDialog extends StatefulWidget {
  const AdminRazaFormDialog({super.key, this.raza});

  final DocumentSnapshot<Map<String, dynamic>>? raza;

  @override
  State<AdminRazaFormDialog> createState() => _AdminRazaFormDialogState();
}

class _AdminRazaFormDialogState extends State<AdminRazaFormDialog> {
  final AdminRazasService _service = AdminRazasService();
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _imagenController = TextEditingController();
  final Map<String, TextEditingController> _bonosControllers = {};
  final Map<String, TextEditingController> _penalizacionesControllers = {};

  static const List<_RazaValorDef> _valoresDisponibles = [
    _RazaValorDef('produccionPct', 'Produccion global'),
    _RazaValorDef('crecimientoPct', 'Crecimiento de poblacion'),
    _RazaValorDef('ataquePct', 'Ataque'),
    _RazaValorDef('defensaPct', 'Defensa'),
    _RazaValorDef('comercioPct', 'Comercio'),
    _RazaValorDef('magiaPct', 'Magia'),
  ];

  bool _activo = true;
  bool _guardando = false;

  bool get _editando => widget.raza != null;

  @override
  void initState() {
    super.initState();

    for (final valor in _valoresDisponibles) {
      _bonosControllers[valor.key] = TextEditingController(text: '0');
      _penalizacionesControllers[valor.key] = TextEditingController(text: '0');
    }

    if (_editando) {
      final data = widget.raza!.data() ?? {};
      final bonos = Map<String, dynamic>.from(data['bonos'] ?? {});
      final penalizaciones = Map<String, dynamic>.from(
        data['penalizaciones'] ?? {},
      );

      _codigoController.text = data['codigo']?.toString() ?? widget.raza!.id;
      _nombreController.text = data['nombre']?.toString() ?? '';
      _descripcionController.text = data['descripcion']?.toString() ?? '';
      _imagenController.text = data['imagenUrl']?.toString() ?? '';
      _activo = data['activo'] as bool? ?? true;

      for (final valor in _valoresDisponibles) {
        _bonosControllers[valor.key]!.text = '${bonos[valor.key] ?? 0}';
        _penalizacionesControllers[valor.key]!.text =
            '${penalizaciones[valor.key] ?? 0}';
      }
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _imagenController.dispose();

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

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Map<String, int> _mapaNumerico(
    Map<String, TextEditingController> controllers,
  ) {
    return {
      for (final valor in _valoresDisponibles)
        valor.key: int.tryParse(controllers[valor.key]!.text.trim()) ?? 0,
    };
  }

  Future<void> _guardar() async {
    if (_formKey.currentState?.validate() != true) return;

    final codigo = _codigo(_codigoController.text);
    if (codigo.isEmpty) {
      _mensaje('El codigo de la raza no es valido.');
      return;
    }

    setState(() => _guardando = true);

    try {
      await _service.guardarRaza(
        razaIdActual: widget.raza?.id,
        codigo: codigo,
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        imagenUrl: _imagenController.text,
        activo: _activo,
        bonos: _mapaNumerico(_bonosControllers),
        penalizaciones: _mapaNumerico(_penalizacionesControllers),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo guardar la raza.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _campo({
    required String label,
    required TextEditingController controller,
    bool numerico = false,
    bool requerido = true,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled && !_guardando,
      maxLines: maxLines,
      keyboardType: numerico ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (requerido && (value == null || value.trim().isEmpty)) {
          return 'Campo obligatorio';
        }

        if (numerico && int.tryParse(value?.trim() ?? '') == null) {
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

  Widget _buildValores({
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
              itemCount: _valoresDisponibles.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnas,
                childAspectRatio: 3.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final valor = _valoresDisponibles[index];

                return _campo(
                  label: '${valor.label} (%)',
                  controller: controllers[valor.key]!,
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
      title: Text(_editando ? 'Editar raza' : 'Crear raza'),
      content: SizedBox(
        width: 780,
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
                _campo(
                  label: 'URL imagen',
                  controller: _imagenController,
                  requerido: false,
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
                _buildValores(titulo: 'Bonos', controllers: _bonosControllers),
                const SizedBox(height: 16),
                _buildValores(
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

class _RazaValorDef {
  const _RazaValorDef(this.key, this.label);

  final String key;
  final String label;
}
