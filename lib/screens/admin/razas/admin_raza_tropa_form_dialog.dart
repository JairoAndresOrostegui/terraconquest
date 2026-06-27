import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_razas_service.dart';

class AdminRazaTropaFormDialog extends StatefulWidget {
  const AdminRazaTropaFormDialog({super.key, required this.razaId, this.tropa});

  final String razaId;
  final DocumentSnapshot<Map<String, dynamic>>? tropa;

  @override
  State<AdminRazaTropaFormDialog> createState() =>
      _AdminRazaTropaFormDialogState();
}

class _AdminRazaTropaFormDialogState extends State<AdminRazaTropaFormDialog> {
  final AdminRazasService _service = AdminRazasService();
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _nivelController = TextEditingController(text: '1');
  final _ataqueController = TextEditingController(text: '0');
  final _defensaController = TextEditingController(text: '0');
  final _danioController = TextEditingController(text: '0');
  final _vidaController = TextEditingController(text: '0');
  final _velocidadController = TextEditingController(text: '0');
  final _moralController = TextEditingController(text: '0');
  final _tipoAtaqueController = TextEditingController(text: 'fisico');
  final _tipoDefensaController = TextEditingController(text: 'normal');
  final _tipoMagiaController = TextEditingController(text: 'ninguno');
  final _habilidadesController = TextEditingController();
  final _costeCompraController = TextEditingController();
  final _mantenimientoController = TextEditingController();
  final _poblacionMinimaController = TextEditingController(text: '0');
  final _diaMinimoController = TextEditingController(text: '1');
  final _diaMaximoController = TextEditingController();
  bool _porFama = false;
  bool _activo = true;
  bool _guardando = false;

  bool get _editando => widget.tropa != null;

  @override
  void initState() {
    super.initState();

    if (_editando) {
      final data = widget.tropa!.data() ?? {};
      final desbloqueo = Map<String, dynamic>.from(data['desbloqueo'] ?? {});

      _codigoController.text = data['codigo']?.toString() ?? widget.tropa!.id;
      _nombreController.text = data['nombre']?.toString() ?? '';
      _descripcionController.text = data['descripcion']?.toString() ?? '';
      _nivelController.text = '${data['nivel'] ?? 1}';
      _ataqueController.text = '${data['ataque'] ?? 0}';
      _defensaController.text = '${data['defensa'] ?? 0}';
      _danioController.text = '${data['danio'] ?? 0}';
      _vidaController.text = '${data['vida'] ?? 0}';
      _velocidadController.text = '${data['velocidad'] ?? 0}';
      _moralController.text = '${data['moral'] ?? 0}';
      _tipoAtaqueController.text = data['tipoAtaque']?.toString() ?? 'fisico';
      _tipoDefensaController.text = data['tipoDefensa']?.toString() ?? 'normal';
      _tipoMagiaController.text = data['tipoMagia']?.toString() ?? 'ninguno';
      _habilidadesController.text = List<String>.from(
        data['habilidades'] ?? [],
      ).join(', ');
      _costeCompraController.text = _mapaATexto(data['costeCompra']);
      _mantenimientoController.text = _mapaATexto(data['mantenimiento']);
      _poblacionMinimaController.text = '${desbloqueo['poblacionMinima'] ?? 0}';
      _diaMinimoController.text = '${desbloqueo['diaMinimo'] ?? 1}';
      _diaMaximoController.text = '${desbloqueo['diaMaximo'] ?? ''}';
      _porFama = desbloqueo['porFama'] == true;
      _activo = data['activo'] as bool? ?? true;
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _codigoController,
      _nombreController,
      _descripcionController,
      _nivelController,
      _ataqueController,
      _defensaController,
      _danioController,
      _vidaController,
      _velocidadController,
      _moralController,
      _tipoAtaqueController,
      _tipoDefensaController,
      _tipoMagiaController,
      _habilidadesController,
      _costeCompraController,
      _mantenimientoController,
      _poblacionMinimaController,
      _diaMinimoController,
      _diaMaximoController,
    ]) {
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

  int _int(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  List<String> _lista(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, int> _mapaRecursos(String value) {
    final resultado = <String, int>{};
    for (final item in value.split(',')) {
      final partes = item.split(':');
      if (partes.length != 2) continue;
      final key = partes[0].trim();
      final valor = int.tryParse(partes[1].trim());
      if (key.isNotEmpty && valor != null) resultado[key] = valor;
    }
    return resultado;
  }

  String _mapaATexto(dynamic value) {
    if (value is! Map) return '';
    return value.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }

  Future<void> _guardar() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _guardando = true);
    try {
      await _service.guardarTropa(
        razaId: widget.razaId,
        tropaIdActual: widget.tropa?.id,
        codigo: _codigo(_codigoController.text),
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        nivel: _int(_nivelController),
        ataque: _int(_ataqueController),
        defensa: _int(_defensaController),
        danio: _int(_danioController),
        vida: _int(_vidaController),
        velocidad: _int(_velocidadController),
        moral: _int(_moralController),
        tipoAtaque: _tipoAtaqueController.text,
        tipoDefensa: _tipoDefensaController.text,
        tipoMagia: _tipoMagiaController.text,
        habilidades: _lista(_habilidadesController.text),
        costeCompra: _mapaRecursos(_costeCompraController.text),
        mantenimiento: _mapaRecursos(_mantenimientoController.text),
        desbloqueo: {
          'poblacionMinima': _int(_poblacionMinimaController),
          'porFama': _porFama,
          'diaMinimo': _int(_diaMinimoController),
          'diaMaximo':
              _diaMaximoController.text.trim().isEmpty
                  ? null
                  : _int(_diaMaximoController),
        },
        activo: _activo,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la tropa.')),
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

  Widget _buildGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth > 720 ? 3 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columnas,
          childAspectRatio: 3.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: children,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editando ? 'Editar tropa' : 'Crear tropa'),
      content: SizedBox(
        width: 820,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGrid([
                  _campo(
                    label: 'Codigo',
                    controller: _codigoController,
                    enabled: !_editando,
                  ),
                  _campo(label: 'Nombre', controller: _nombreController),
                  _campo(
                    label: 'Nivel',
                    controller: _nivelController,
                    numerico: true,
                  ),
                ]),
                const SizedBox(height: 12),
                _campo(
                  label: 'Descripcion',
                  controller: _descripcionController,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Stats',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildGrid([
                  _campo(
                    label: 'Ataque',
                    controller: _ataqueController,
                    numerico: true,
                  ),
                  _campo(
                    label: 'Defensa',
                    controller: _defensaController,
                    numerico: true,
                  ),
                  _campo(
                    label: 'Daño',
                    controller: _danioController,
                    numerico: true,
                  ),
                  _campo(
                    label: 'Vida',
                    controller: _vidaController,
                    numerico: true,
                  ),
                  _campo(
                    label: 'Velocidad',
                    controller: _velocidadController,
                    numerico: true,
                  ),
                  _campo(
                    label: 'Moral',
                    controller: _moralController,
                    numerico: true,
                  ),
                ]),
                const SizedBox(height: 16),
                const Text(
                  'Tipos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildGrid([
                  _campo(
                    label: 'Tipo ataque',
                    controller: _tipoAtaqueController,
                  ),
                  _campo(
                    label: 'Tipo defensa',
                    controller: _tipoDefensaController,
                  ),
                  _campo(label: 'Tipo magia', controller: _tipoMagiaController),
                ]),
                const SizedBox(height: 12),
                _campo(
                  label: 'Habilidades (separadas por coma)',
                  controller: _habilidadesController,
                ),
                const SizedBox(height: 16),
                _campo(
                  label: 'Coste compra (ej: oro: 100, alimentos: 20)',
                  controller: _costeCompraController,
                ),
                const SizedBox(height: 12),
                _campo(
                  label: 'Mantenimiento (ej: oro: 2, alimentos: 1)',
                  controller: _mantenimientoController,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Desbloqueo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildGrid([
                  _campo(
                    label: 'Poblacion minima',
                    controller: _poblacionMinimaController,
                    numerico: true,
                  ),
                  _campo(
                    label: 'Dia minimo',
                    controller: _diaMinimoController,
                    numerico: true,
                  ),
                  TextFormField(
                    controller: _diaMaximoController,
                    enabled: !_guardando,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dia maximo (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ]),
                CheckboxListTile(
                  value: _porFama,
                  title: const Text('Desbloqueo por fama'),
                  onChanged:
                      _guardando
                          ? null
                          : (value) =>
                              setState(() => _porFama = value ?? false),
                ),
                SwitchListTile(
                  title: const Text('Activa'),
                  value: _activo,
                  onChanged:
                      _guardando
                          ? null
                          : (value) => setState(() => _activo = value),
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
