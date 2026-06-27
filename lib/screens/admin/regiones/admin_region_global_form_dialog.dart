import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_regiones_service.dart';

class AdminRegionGlobalFormDialog extends StatefulWidget {
  const AdminRegionGlobalFormDialog({super.key, this.region});

  final DocumentSnapshot<Map<String, dynamic>>? region;

  @override
  State<AdminRegionGlobalFormDialog> createState() =>
      _AdminRegionGlobalFormDialogState();
}

class _AdminRegionGlobalFormDialogState
    extends State<AdminRegionGlobalFormDialog> {
  final AdminRegionesService _service = AdminRegionesService();
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _imagenController = TextEditingController();
  final Map<String, TextEditingController> _bonosControllers = {};
  final Set<String> _bonosSeleccionados = {};
  final Set<String> _terrenosSeleccionados = {};

  static const List<_BonoRegionDef> _bonosDisponibles = [
    _BonoRegionDef('produccionPct', 'Produccion global'),
    _BonoRegionDef('crecimientoPct', 'Crecimiento de poblacion'),
    _BonoRegionDef('famaPct', 'Fama'),
    _BonoRegionDef('ataquePct', 'Ataque del imperio'),
    _BonoRegionDef('defensaPct', 'Defensa del imperio'),
    _BonoRegionDef('questHeroePct', 'Exito de quest con heroe'),
    _BonoRegionDef('heroeAtaquePct', 'Ataque de heroes'),
    _BonoRegionDef('heroeDefensaPct', 'Defensa de heroes'),
    _BonoRegionDef('heroeMagiaPct', 'Magia de heroes'),
    _BonoRegionDef('heroeVidaPct', 'Vida de heroes'),
    _BonoRegionDef('oroPct', 'Produccion de oro'),
    _BonoRegionDef('alimentosPct', 'Produccion de alimentos'),
    _BonoRegionDef('aguaPct', 'Produccion de agua'),
    _BonoRegionDef('maderaPct', 'Produccion de madera'),
    _BonoRegionDef('piedraPct', 'Produccion de piedra'),
    _BonoRegionDef('hierroPct', 'Produccion de hierro'),
    _BonoRegionDef('herramientasPct', 'Produccion de herramientas'),
    _BonoRegionDef('armasPct', 'Produccion de armas'),
    _BonoRegionDef('bloquesPct', 'Produccion de bloques'),
    _BonoRegionDef('tablasPct', 'Produccion de tablas'),
    _BonoRegionDef('mithrilPct', 'Produccion de mithril'),
    _BonoRegionDef('cristalPct', 'Produccion de cristal'),
    _BonoRegionDef('plataPct', 'Produccion de plata'),
    _BonoRegionDef('reliquiasPct', 'Produccion de reliquias'),
    _BonoRegionDef('gemasPct', 'Produccion de gemas'),
    _BonoRegionDef('joyasPct', 'Produccion de joyas'),
    _BonoRegionDef('manaPct', 'Produccion de mana'),
    _BonoRegionDef('karmaPct', 'Produccion de karma'),
  ];

  bool _activo = true;
  bool _guardando = false;
  bool _cargandoTerrenos = true;
  String? _bonoParaAgregar;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _terrenos = [];

  bool get _editando => widget.region != null;

  @override
  void initState() {
    super.initState();

    for (final bono in _bonosDisponibles) {
      _bonosControllers[bono.key] = TextEditingController(text: '0');
    }

    if (_editando) {
      final data = widget.region!.data() ?? {};
      final bonos = Map<String, dynamic>.from(data['bonos'] ?? {});

      _nombreController.text = data['nombre']?.toString() ?? '';
      _codigoController.text = data['codigo']?.toString() ?? '';
      _descripcionController.text = data['descripcion']?.toString() ?? '';
      _imagenController.text = data['imagenUrl']?.toString() ?? '';
      _activo = data['activo'] as bool? ?? true;
      _terrenosSeleccionados.addAll(
        List<String>.from(data['terrenosPermitidos'] ?? []),
      );

      for (final bono in _bonosDisponibles) {
        final valor = bonos[bono.key];
        _bonosControllers[bono.key]!.text = '${valor ?? 0}';
        if (valor is num && valor != 0) {
          _bonosSeleccionados.add(bono.key);
        }
      }
    }

    _cargarTerrenos();
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Map<String, int> _obtenerBonos() {
    return {
      for (final key in _bonosSeleccionados)
        if ((int.tryParse(_bonosControllers[key]!.text.trim()) ?? 0) != 0)
          key: int.tryParse(_bonosControllers[key]!.text.trim()) ?? 0,
    };
  }

  Future<void> _guardar() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_terrenosSeleccionados.isEmpty) {
      _mensaje('Selecciona al menos un terreno permitido.');
      return;
    }

    setState(() => _guardando = true);

    try {
      await _service.guardarRegionGlobal(
        regionId: widget.region?.id,
        nombre: _nombreController.text,
        codigo: _codigoController.text,
        descripcion: _descripcionController.text,
        imagenUrl: _imagenController.text,
        activo: _activo,
        terrenosPermitidos: _terrenosSeleccionados.toList(),
        bonos: _obtenerBonos(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo guardar la region.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _campo({
    required String label,
    required TextEditingController controller,
    bool numerico = false,
    bool requerido = true,
  }) {
    return TextFormField(
      controller: controller,
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
          'Terrenos que puede contener',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._terrenos.map((terreno) {
          final data = terreno.data();
          final seleccionado = _terrenosSeleccionados.contains(terreno.id);

          return CheckboxListTile(
            value: seleccionado,
            title: Text(data['nombre']?.toString() ?? terreno.id),
            subtitle: Text(data['codigo']?.toString() ?? terreno.id),
            onChanged:
                _guardando
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

  Widget _buildBonos() {
    final bonosRestantes =
        _bonosDisponibles
            .where((bono) => !_bonosSeleccionados.contains(bono.key))
            .toList();
    final seleccionados =
        _bonosDisponibles
            .where((bono) => _bonosSeleccionados.contains(bono.key))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bonos propios de la region',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                  'bono-${_bonoParaAgregar ?? 'none'}-${_bonosSeleccionados.length}',
                ),
                initialValue: _bonoParaAgregar,
                decoration: const InputDecoration(
                  labelText: 'Tipo de bono',
                  border: OutlineInputBorder(),
                ),
                items:
                    bonosRestantes.map((bono) {
                      return DropdownMenuItem<String>(
                        value: bono.key,
                        child: Text(bono.label),
                      );
                    }).toList(),
                onChanged:
                    _guardando
                        ? null
                        : (value) => setState(() => _bonoParaAgregar = value),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Agregar bono',
              onPressed:
                  _guardando || _bonoParaAgregar == null
                      ? null
                      : () {
                        setState(() {
                          _bonosSeleccionados.add(_bonoParaAgregar!);
                          _bonoParaAgregar = null;
                        });
                      },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (seleccionados.isEmpty)
          const Text('Sin bonos configurados.')
        else
          ...seleccionados.map((bono) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _campo(
                      label: '${bono.label} (%)',
                      controller: _bonosControllers[bono.key]!,
                      numerico: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Quitar bono',
                    onPressed:
                        _guardando
                            ? null
                            : () {
                              setState(() {
                                _bonosSeleccionados.remove(bono.key);
                                _bonosControllers[bono.key]!.text = '0';
                              });
                            },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editando ? 'Editar region' : 'Crear region'),
      content: SizedBox(
        width: 780,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _campo(label: 'Nombre', controller: _nombreController),
                const SizedBox(height: 12),
                _campo(label: 'Codigo', controller: _codigoController),
                const SizedBox(height: 12),
                _campo(
                  label: 'Descripcion',
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
                  title: const Text('Activa'),
                  value: _activo,
                  onChanged:
                      _guardando
                          ? null
                          : (value) => setState(() => _activo = value),
                ),
                const SizedBox(height: 16),
                _buildTerrenos(),
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
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: Text(_guardando ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}

class _BonoRegionDef {
  const _BonoRegionDef(this.key, this.label);

  final String key;
  final String label;
}
