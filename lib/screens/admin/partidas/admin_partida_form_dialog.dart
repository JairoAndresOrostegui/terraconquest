import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_partidas_crud_service.dart';
import '../../../services/admin_regiones_service.dart';

class AdminPartidaFormDialog extends StatefulWidget {
  const AdminPartidaFormDialog({super.key, this.partida});

  final DocumentSnapshot<Map<String, dynamic>>? partida;

  @override
  State<AdminPartidaFormDialog> createState() => _AdminPartidaFormDialogState();
}

class _AdminPartidaFormDialogState extends State<AdminPartidaFormDialog> {
  final AdminPartidasCrudService _service = AdminPartidasCrudService();
  final AdminRegionesService _regionesService = AdminRegionesService();
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _rondaController = TextEditingController();
  final _mapaIdController = TextEditingController();
  final _imagenMapaUrlController = TextEditingController();
  final _diaActualController = TextEditingController();
  final _totalDiasController = TextEditingController();
  final _horasProteccionController = TextEditingController();
  final _horasProteccionAtaqueController = TextEditingController();
  final _maxImperiosClanController = TextEditingController();

  String _estado = 'futura';
  bool _permitirRegistro = true;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _guardando = false;
  bool _cargandoRegiones = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _regiones = [];
  final Set<String> _regionesSeleccionadas = {};
  String? _regionParaAgregar;

  bool get _editando => widget.partida != null;

  @override
  void initState() {
    super.initState();

    if (_editando) {
      final data = widget.partida!.data() ?? {};

      _nombreController.text = data['nombre']?.toString() ?? '';
      _rondaController.text = '${data['ronda'] ?? 1}';
      _mapaIdController.text = data['mapaId']?.toString() ?? '';
      _imagenMapaUrlController.text = data['imagenMapaUrl']?.toString() ?? '';
      _diaActualController.text = '${data['diaActual'] ?? 1}';
      _totalDiasController.text = '${data['totalDias'] ?? 60}';
      _horasProteccionController.text =
          '${data['horasProteccionInicial'] ?? 24}';
      _horasProteccionAtaqueController.text =
          '${data['horasProteccionAtaque'] ?? 12}';
      _maxImperiosClanController.text = '${data['maxImperiosPorClan'] ?? 5}';
      _estado = data['estado']?.toString() ?? 'futura';
      _permitirRegistro = data['permitirRegistro'] as bool? ?? true;
      _fechaInicio = (data['fechaInicio'] as Timestamp?)?.toDate();
      _fechaFin = (data['fechaFin'] as Timestamp?)?.toDate();
      _regionesSeleccionadas.addAll(
        List<String>.from(data['regionesDisponibles'] ?? []),
      );
    } else {
      _rondaController.text = '1';
      _mapaIdController.text = 'mapa_prueba';
      _imagenMapaUrlController.text = '';
      _diaActualController.text = '1';
      _totalDiasController.text = '60';
      _horasProteccionController.text = '24';
      _horasProteccionAtaqueController.text = '12';
      _maxImperiosClanController.text = '5';
      _fechaInicio = DateTime.now();
    }

    _cargarRegiones();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _rondaController.dispose();
    _mapaIdController.dispose();
    _imagenMapaUrlController.dispose();
    _diaActualController.dispose();
    _totalDiasController.dispose();
    _horasProteccionController.dispose();
    _horasProteccionAtaqueController.dispose();
    _maxImperiosClanController.dispose();
    super.dispose();
  }

  int _intValue(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  Future<void> _cargarRegiones() async {
    try {
      final regiones = await _regionesService.obtenerRegionesParaPartidas();
      if (!mounted) return;

      setState(() {
        _regiones = regiones;
        _cargandoRegiones = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoRegiones = false);
      _mostrarMensaje('No se pudieron cargar las regiones.');
    }
  }

  Future<void> _seleccionarFecha({required bool inicio}) async {
    final actual = inicio ? _fechaInicio : _fechaFin;
    final seleccion = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (seleccion == null) return;

    setState(() {
      if (inicio) {
        _fechaInicio = seleccion;
      } else {
        _fechaFin = seleccion;
      }
    });
  }

  String _textoFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar';
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _guardar() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_fechaInicio == null) {
      _mostrarMensaje('Selecciona la fecha de inicio.');
      return;
    }

    if (_fechaFin != null && _fechaFin!.isBefore(_fechaInicio!)) {
      _mostrarMensaje(
        'La fecha final no puede ser anterior a la fecha de inicio.',
      );
      return;
    }

    if (_regionesSeleccionadas.isEmpty) {
      _mostrarMensaje('Selecciona al menos una region disponible.');
      return;
    }

    setState(() => _guardando = true);

    try {
      if (_editando) {
        await _service.actualizarPartida(
          partidaId: widget.partida!.id,
          nombre: _nombreController.text,
          ronda: _intValue(_rondaController),
          estado: _estado,
          mapaId: _mapaIdController.text,
          imagenMapaUrl: _imagenMapaUrlController.text,
          fechaInicio: _fechaInicio!,
          fechaFin: _fechaFin,
          diaActual: _intValue(_diaActualController),
          totalDias: _intValue(_totalDiasController),
          horasProteccionInicial: _intValue(_horasProteccionController),
          horasProteccionAtaque: _intValue(_horasProteccionAtaqueController),
          maxImperiosPorClan: _intValue(_maxImperiosClanController),
          permitirRegistro: _permitirRegistro,
          regionesDisponibles: _regionesSeleccionadas.toList(),
        );
      } else {
        await _service.crearPartida(
          nombre: _nombreController.text,
          ronda: _intValue(_rondaController),
          estado: _estado,
          mapaId: _mapaIdController.text,
          imagenMapaUrl: _imagenMapaUrlController.text,
          fechaInicio: _fechaInicio!,
          fechaFin: _fechaFin,
          totalDias: _intValue(_totalDiasController),
          horasProteccionInicial: _intValue(_horasProteccionController),
          horasProteccionAtaque: _intValue(_horasProteccionAtaqueController),
          maxImperiosPorClan: _intValue(_maxImperiosClanController),
          permitirRegistro: _permitirRegistro,
          regionesDisponibles: _regionesSeleccionadas.toList(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensaje('No se pudo guardar la partida.');
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Widget _campoTexto({
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

  Widget _buildRegiones() {
    if (_cargandoRegiones) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_regiones.isEmpty) {
      return const Text(
        'No hay regiones creadas. Crea regiones antes de crear partidas.',
      );
    }

    final regionesDisponibles =
        _regiones
            .where((region) => !_regionesSeleccionadas.contains(region.id))
            .toList();
    final regionesSeleccionadas =
        _regiones
            .where((region) => _regionesSeleccionadas.contains(region.id))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Regiones disponibles en la partida',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                  'region-${_regionParaAgregar ?? 'none'}-${_regionesSeleccionadas.length}',
                ),
                initialValue: _regionParaAgregar,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Agregar region',
                  border: OutlineInputBorder(),
                ),
                items:
                    regionesDisponibles.map((region) {
                      final data = region.data();
                      final nombre = data['nombre']?.toString() ?? region.id;
                      final codigo = data['codigo']?.toString() ?? region.id;
                      final activo = data['activo'] as bool? ?? true;

                      return DropdownMenuItem<String>(
                        value: region.id,
                        child: Text(
                          activo
                              ? '$codigo - $nombre'
                              : '$codigo - $nombre (inactiva)',
                        ),
                      );
                    }).toList(),
                onChanged:
                    _guardando || regionesDisponibles.isEmpty
                        ? null
                        : (value) => setState(() => _regionParaAgregar = value),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Agregar region',
              onPressed:
                  _guardando || _regionParaAgregar == null
                      ? null
                      : () {
                        setState(() {
                          _regionesSeleccionadas.add(_regionParaAgregar!);
                          _regionParaAgregar = null;
                        });
                      },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (regionesSeleccionadas.isEmpty)
          const Text('Sin regiones agregadas.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                regionesSeleccionadas.map((region) {
                  final data = region.data();
                  final nombre = data['nombre']?.toString() ?? region.id;
                  final codigo = data['codigo']?.toString() ?? region.id;

                  return InputChip(
                    label: Text('$codigo - $nombre'),
                    onDeleted:
                        _guardando
                            ? null
                            : () {
                              setState(() {
                                _regionesSeleccionadas.remove(region.id);
                              });
                            },
                  );
                }).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editando ? 'Editar partida' : 'Crear partida'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _campoTexto(label: 'Nombre', controller: _nombreController),
                const SizedBox(height: 12),
                _campoTexto(
                  label: 'Ronda',
                  controller: _rondaController,
                  numerico: true,
                ),
                const SizedBox(height: 12),
                _campoTexto(label: 'Mapa ID', controller: _mapaIdController),
                const SizedBox(height: 12),
                _campoTexto(
                  label: 'URL imagen del mapa',
                  controller: _imagenMapaUrlController,
                  requerido: false,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _estado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'futura', child: Text('Futura')),
                    DropdownMenuItem(value: 'activa', child: Text('Activa')),
                    DropdownMenuItem(
                      value: 'finalizada',
                      child: Text('Finalizada'),
                    ),
                  ],
                  onChanged:
                      _guardando
                          ? null
                          : (value) =>
                              setState(() => _estado = value ?? 'futura'),
                ),
                const SizedBox(height: 12),
                _campoTexto(
                  label: 'Día actual',
                  controller: _diaActualController,
                  numerico: true,
                ),
                const SizedBox(height: 12),
                _campoTexto(
                  label: 'Total días',
                  controller: _totalDiasController,
                  numerico: true,
                ),
                const SizedBox(height: 12),
                _campoTexto(
                  label: 'Horas protección inicial',
                  controller: _horasProteccionController,
                  numerico: true,
                ),
                const SizedBox(height: 12),
                _campoTexto(
                  label: 'Horas protección tras ataque',
                  controller: _horasProteccionAtaqueController,
                  numerico: true,
                ),
                const SizedBox(height: 12),
                _campoTexto(
                  label: 'Máximo imperios por clan',
                  controller: _maxImperiosClanController,
                  numerico: true,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Permitir registro'),
                  value: _permitirRegistro,
                  onChanged:
                      _guardando
                          ? null
                          : (value) =>
                              setState(() => _permitirRegistro = value),
                ),
                const SizedBox(height: 12),
                _buildRegiones(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _guardando
                                ? null
                                : () => _seleccionarFecha(inicio: true),
                        child: Text('Inicio: ${_textoFecha(_fechaInicio)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _guardando
                                ? null
                                : () => _seleccionarFecha(inicio: false),
                        child: Text('Fin: ${_textoFecha(_fechaFin)}'),
                      ),
                    ),
                  ],
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
        Semantics(
          button: true,
          enabled: !_guardando,
          focusable: true,
          label: _editando ? 'Guardar cambios de partida' : 'Crear partida',
          child: FilledButton(
            onPressed: _guardando ? null : _guardar,
            child: Text(_guardando ? 'Guardando...' : 'Guardar'),
          ),
        ),
      ],
    );
  }
}
