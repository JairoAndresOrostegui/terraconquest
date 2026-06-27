import 'package:flutter/material.dart';

import '../../../models/region_model.dart';
import '../../../models/terreno_model.dart';
import '../../../services/catalogo_juego_service.dart';
import '../../../services/ciudad_service.dart';
import 'ciudad_detalle_screen.dart';

class FundarCiudadScreen extends StatefulWidget {
  const FundarCiudadScreen({
    super.key,
    required this.partidaId,
    required this.imperioId,
  });

  final String partidaId;
  final String imperioId;

  @override
  State<FundarCiudadScreen> createState() => _FundarCiudadScreenState();
}

class _FundarCiudadScreenState extends State<FundarCiudadScreen> {
  final CatalogoJuegoService _catalogoService = CatalogoJuegoService();
  final CiudadService _ciudadService = CiudadService();
  final TextEditingController _nombreController = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;

  List<RegionModel> _regiones = [];
  List<TerrenoModel> _terrenos = [];

  RegionModel? _regionSeleccionada;
  TerrenoModel? _terrenoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final resultados = await Future.wait([
        _catalogoService.obtenerRegionesDePartida(widget.partidaId),
        _catalogoService.obtenerTerrenosActivos(),
      ]);

      if (!mounted) return;

      setState(() {
        _regiones = resultados[0] as List<RegionModel>;
        _terrenos = resultados[1] as List<TerrenoModel>;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      _mensaje('No se pudieron cargar las regiones y terrenos.');
    }
  }

  List<TerrenoModel> get _terrenosDisponibles {
    final region = _regionSeleccionada;
    if (region == null) return [];

    return _terrenos.where((terreno) {
      return region.terrenosPermitidos.contains(terreno.id) ||
          region.terrenosPermitidos.contains(terreno.codigo);
    }).toList();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  bool _validar() {
    final nombre = _nombreController.text.trim();

    if (nombre.length < 3 || nombre.length > 30) {
      _mensaje('El nombre de la ciudad debe tener entre 3 y 30 caracteres.');
      return false;
    }

    if (_regionSeleccionada == null) {
      _mensaje('Selecciona una región.');
      return false;
    }

    if (_terrenoSeleccionado == null) {
      _mensaje('Selecciona un terreno.');
      return false;
    }

    return true;
  }

  Future<void> _fundarCiudad() async {
    if (!_validar()) return;

    setState(() {
      _guardando = true;
    });

    try {
      final result = await _ciudadService.fundarCiudad(
        partidaId: widget.partidaId,
        imperioId: widget.imperioId,
        nombreCiudad: _nombreController.text.trim(),
        regionId: _regionSeleccionada!.id,
        terrenoId: _terrenoSeleccionado!.id,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => CiudadDetalleScreen(
                partidaId: widget.partidaId,
                ciudadId: result['ciudadId'].toString(),
              ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo fundar la ciudad. Revisa turnos, región y nombre.');
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Widget _buildNombreField() {
    return Semantics(
      textField: true,
      focusable: true,
      label: 'Nombre de la nueva ciudad',
      child: TextField(
        controller: _nombreController,
        maxLength: 30,
        decoration: const InputDecoration(
          labelText: 'Nombre de ciudad',
          border: OutlineInputBorder(),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildRegionDropdown() {
    return Semantics(
      focusable: true,
      label: 'Selector de región para fundar ciudad',
      child: DropdownButtonFormField<RegionModel>(
        initialValue: _regionSeleccionada,
        decoration: const InputDecoration(
          labelText: 'Región',
          border: OutlineInputBorder(),
        ),
        items:
            _regiones.map((region) {
              return DropdownMenuItem<RegionModel>(
                value: region,
                child: Text('${region.codigo} - ${region.nombre}'),
              );
            }).toList(),
        onChanged:
            _guardando
                ? null
                : (value) {
                  setState(() {
                    _regionSeleccionada = value;
                    _terrenoSeleccionado = null;
                  });
                },
      ),
    );
  }

  Widget _buildTerrenoDropdown() {
    return Semantics(
      focusable: true,
      label: 'Selector de terreno para fundar ciudad',
      child: DropdownButtonFormField<TerrenoModel>(
        initialValue: _terrenoSeleccionado,
        decoration: const InputDecoration(
          labelText: 'Terreno',
          border: OutlineInputBorder(),
        ),
        items:
            _terrenosDisponibles.map((terreno) {
              return DropdownMenuItem<TerrenoModel>(
                value: terreno,
                child: Text(terreno.nombre),
              );
            }).toList(),
        onChanged:
            _guardando || _regionSeleccionada == null
                ? null
                : (value) {
                  setState(() {
                    _terrenoSeleccionado = value;
                  });
                },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Fundar ciudad')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nueva ciudad',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildNombreField(),
                const SizedBox(height: 14),
                _buildRegionDropdown(),
                const SizedBox(height: 14),
                _buildTerrenoDropdown(),
                const SizedBox(height: 24),
                Semantics(
                  button: true,
                  enabled: !_guardando,
                  focusable: true,
                  label: 'Fundar ciudad',
                  child: FilledButton.icon(
                    onPressed: _guardando ? null : _fundarCiudad,
                    icon:
                        _guardando
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.add_location_alt),
                    label: Text(_guardando ? 'Fundando...' : 'Fundar ciudad'),
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
