import 'package:flutter/material.dart';

import '../../../models/tropa_ciudad_model.dart';
import '../../../services/ejercito_service.dart';
import '../../../services/tropas_service.dart';

class MoverTropasScreen extends StatefulWidget {
  const MoverTropasScreen({
    super.key,
    required this.partidaId,
    required this.imperioId,
  });

  final String partidaId;
  final String imperioId;

  @override
  State<MoverTropasScreen> createState() => _MoverTropasScreenState();
}

class _MoverTropasScreenState extends State<MoverTropasScreen> {
  final EjercitoService _ejercitoService = EjercitoService();
  final TropasService _tropasService = TropasService();
  final TextEditingController _cantidadController = TextEditingController();

  bool _cargando = true;
  bool _moviendo = false;
  List<CiudadConTropas> _ciudades = [];

  CiudadConTropas? _origen;
  CiudadConTropas? _destino;
  TropaCiudadModel? _tropa;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final ciudades = await _ejercitoService.obtenerEjercitoImperio(
        partidaId: widget.partidaId,
        imperioId: widget.imperioId,
      );

      if (!mounted) return;

      setState(() {
        _ciudades = ciudades;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _cargando = false);
      _mensaje('No se pudieron cargar las ciudades y tropas.');
    }
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  bool _validar() {
    if (_origen == null) {
      _mensaje('Selecciona una ciudad origen.');
      return false;
    }

    if (_destino == null) {
      _mensaje('Selecciona una ciudad destino.');
      return false;
    }

    if (_origen!.ciudad.id == _destino!.ciudad.id) {
      _mensaje('La ciudad origen y destino no pueden ser la misma.');
      return false;
    }

    if (_tropa == null) {
      _mensaje('Selecciona una tropa.');
      return false;
    }

    final cantidad = int.tryParse(_cantidadController.text.trim()) ?? 0;

    if (cantidad <= 0) {
      _mensaje('Ingresa una cantidad válida.');
      return false;
    }

    if (cantidad > _tropa!.cantidad) {
      _mensaje('No puedes mover más tropas de las que tienes.');
      return false;
    }

    return true;
  }

  Future<void> _mover() async {
    if (!_validar()) return;

    setState(() => _moviendo = true);

    try {
      await _tropasService.moverTropasCiudad(
        partidaId: widget.partidaId,
        ciudadOrigenId: _origen!.ciudad.id,
        ciudadDestinoId: _destino!.ciudad.id,
        tropaId: _tropa!.tropaId,
        cantidad: int.parse(_cantidadController.text.trim()),
      );

      if (!mounted) return;

      _mensaje('Tropas movidas correctamente.');
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudieron mover las tropas. Revisa turnos y capacidad.');
    } finally {
      if (mounted) {
        setState(() => _moviendo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tropasOrigen = _origen?.tropas ?? [];
    final ciudadesDestino = _ciudades
        .where((item) => item.ciudad.id != _origen?.ciudad.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mover tropas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  focusable: true,
                  label: 'Seleccionar ciudad origen',
                  child: DropdownButtonFormField<CiudadConTropas>(
                    initialValue: _origen,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad origen',
                      border: OutlineInputBorder(),
                    ),
                    items: _ciudades.map((item) {
                      return DropdownMenuItem<CiudadConTropas>(
                        value: item,
                        child: Text(item.ciudad.nombre),
                      );
                    }).toList(),
                    onChanged: _moviendo
                        ? null
                        : (value) {
                            setState(() {
                              _origen = value;
                              _tropa = null;
                              if (_destino?.ciudad.id == value?.ciudad.id) {
                                _destino = null;
                              }
                            });
                          },
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  focusable: true,
                  label: 'Seleccionar tropa a mover',
                  child: DropdownButtonFormField<TropaCiudadModel>(
                    initialValue: _tropa,
                    decoration: const InputDecoration(
                      labelText: 'Tropa',
                      border: OutlineInputBorder(),
                    ),
                    items: tropasOrigen.map((tropa) {
                      return DropdownMenuItem<TropaCiudadModel>(
                        value: tropa,
                        child: Text(
                          '${tropa.nombre} - ${tropa.cantidad} disponibles',
                        ),
                      );
                    }).toList(),
                    onChanged: _moviendo || _origen == null
                        ? null
                        : (value) {
                            setState(() {
                              _tropa = value;
                            });
                          },
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  focusable: true,
                  label: 'Seleccionar ciudad destino',
                  child: DropdownButtonFormField<CiudadConTropas>(
                    initialValue: _destino,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad destino',
                      border: OutlineInputBorder(),
                    ),
                    items: ciudadesDestino.map((item) {
                      return DropdownMenuItem<CiudadConTropas>(
                        value: item,
                        child: Text(item.ciudad.nombre),
                      );
                    }).toList(),
                    onChanged: _moviendo
                        ? null
                        : (value) {
                            setState(() {
                              _destino = value;
                            });
                          },
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  textField: true,
                  focusable: true,
                  label: 'Cantidad de tropas a mover',
                  child: TextField(
                    controller: _cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  button: true,
                  enabled: !_moviendo,
                  focusable: true,
                  label: 'Mover tropas',
                  child: FilledButton.icon(
                    onPressed: _moviendo ? null : _mover,
                    icon: _moviendo
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.swap_horiz),
                    label: Text(_moviendo ? 'Moviendo...' : 'Mover tropas'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
