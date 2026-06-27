import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../models/raza_model.dart';
import '../../models/region_model.dart';
import '../../models/terreno_model.dart';
import '../../services/catalogo_juego_service.dart';
import '../../services/imperio_service.dart';
import 'imperio_dashboard_screen.dart';

class CrearImperioScreen extends StatefulWidget {
  const CrearImperioScreen({super.key, required this.partidaId});

  final String partidaId;

  @override
  State<CrearImperioScreen> createState() => _CrearImperioScreenState();
}

class _CrearImperioScreenState extends State<CrearImperioScreen> {
  final CatalogoJuegoService _catalogoService = CatalogoJuegoService();
  final ImperioService _imperioService = ImperioService();
  final TextEditingController _nombreImperioController =
      TextEditingController();
  final TextEditingController _nombreCiudadController = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;

  List<RazaModel> _razas = [];
  List<RegionModel> _regiones = [];
  List<TerrenoModel> _terrenos = [];

  RazaModel? _razaSeleccionada;
  RegionModel? _regionSeleccionada;
  TerrenoModel? _terrenoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _nombreImperioController.dispose();
    _nombreCiudadController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      final razasFuture = _catalogoService.obtenerRazasActivas();
      final regionesFuture = _catalogoService.obtenerRegionesDePartida(
        widget.partidaId,
      );
      final terrenosFuture = _catalogoService.obtenerTerrenosActivos();

      final resultados = await Future.wait([
        razasFuture,
        regionesFuture,
        terrenosFuture,
      ]);

      if (!mounted) return;

      setState(() {
        _razas = resultados[0] as List<RazaModel>;
        _regiones = resultados[1] as List<RegionModel>;
        _terrenos = resultados[2] as List<TerrenoModel>;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _cargando = false);
      _mostrarMensaje('No se pudieron cargar los datos para crear el imperio.');
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

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  bool _validarFormulario() {
    final nombreImperio = _nombreImperioController.text.trim();
    final nombreCiudad = _nombreCiudadController.text.trim();

    if (_razaSeleccionada == null) {
      _mostrarMensaje('Selecciona una raza.');
      return false;
    }

    if (nombreImperio.length < 3 || nombreImperio.length > 30) {
      _mostrarMensaje(
        'El nombre del imperio debe tener entre 3 y 30 caracteres.',
      );
      return false;
    }

    if (nombreCiudad.length < 3 || nombreCiudad.length > 30) {
      _mostrarMensaje(
        'El nombre de la ciudad debe tener entre 3 y 30 caracteres.',
      );
      return false;
    }

    if (_regionSeleccionada == null) {
      _mostrarMensaje('Selecciona una región.');
      return false;
    }

    if (_terrenoSeleccionado == null) {
      _mostrarMensaje('Selecciona un terreno.');
      return false;
    }

    return true;
  }

  Future<void> _crearImperio() async {
    if (!_validarFormulario()) return;

    setState(() => _guardando = true);

    try {
      final result = await _imperioService.crearImperio(
        partidaId: widget.partidaId,
        razaId: _razaSeleccionada!.id,
        nombreImperio: _nombreImperioController.text.trim(),
        nombreCiudad: _nombreCiudadController.text.trim(),
        regionId: _regionSeleccionada!.id,
        terrenoId: _terrenoSeleccionado!.id,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => ImperioDashboardScreen(
                partidaId: widget.partidaId,
                imperioId: result['imperioId'].toString(),
              ),
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        error.message ??
            'No se pudo crear el imperio. Revisa los datos e inténtalo nuevamente.',
      );
    } catch (_) {
      if (!mounted) return;
      _mostrarMensaje(
        'No se pudo crear el imperio. Revisa los datos e inténtalo nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Widget _buildCampoTexto({
    required String label,
    required TextEditingController controller,
    required String semanticLabel,
  }) {
    return Semantics(
      textField: true,
      focusable: true,
      label: semanticLabel,
      child: TextField(
        controller: controller,
        enabled: !_guardando,
        maxLength: 30,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildDropdownRaza() {
    return Semantics(
      focusable: true,
      label: 'Selector de raza del imperio',
      child: DropdownButtonFormField<RazaModel>(
        initialValue: _razaSeleccionada,
        decoration: const InputDecoration(
          labelText: 'Raza',
          border: OutlineInputBorder(),
        ),
        items:
            _razas.map((raza) {
              return DropdownMenuItem<RazaModel>(
                value: raza,
                child: Text(raza.nombre),
              );
            }).toList(),
        onChanged:
            _guardando
                ? null
                : (value) {
                  setState(() => _razaSeleccionada = value);
                },
      ),
    );
  }

  Widget _buildDropdownRegion() {
    return Semantics(
      focusable: true,
      label: 'Selector de región inicial',
      child: DropdownButtonFormField<RegionModel>(
        initialValue: _regionSeleccionada,
        decoration: const InputDecoration(
          labelText: 'Región inicial',
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

  Widget _buildDropdownTerreno() {
    final disponibles = _terrenosDisponibles;

    return Semantics(
      focusable: true,
      label: 'Selector de terreno inicial',
      child: DropdownButtonFormField<TerrenoModel>(
        initialValue: _terrenoSeleccionado,
        decoration: const InputDecoration(
          labelText: 'Terreno inicial',
          border: OutlineInputBorder(),
        ),
        items:
            disponibles.map((terreno) {
              return DropdownMenuItem<TerrenoModel>(
                value: terreno,
                child: Text(terreno.nombre),
              );
            }).toList(),
        onChanged:
            _guardando || _regionSeleccionada == null
                ? null
                : (value) {
                  setState(() => _terrenoSeleccionado = value);
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
      appBar: AppBar(title: const Text('Crear imperio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nuevo imperio',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Elige tu raza, define el nombre de tu imperio y crea tu primera ciudad.',
                ),
                const SizedBox(height: 20),
                _buildDropdownRaza(),
                const SizedBox(height: 14),
                _buildCampoTexto(
                  label: 'Nombre del imperio',
                  controller: _nombreImperioController,
                  semanticLabel: 'Campo para escribir el nombre del imperio',
                ),
                const SizedBox(height: 14),
                _buildCampoTexto(
                  label: 'Nombre de la ciudad inicial',
                  controller: _nombreCiudadController,
                  semanticLabel:
                      'Campo para escribir el nombre de la ciudad inicial',
                ),
                const SizedBox(height: 14),
                _buildDropdownRegion(),
                const SizedBox(height: 14),
                _buildDropdownTerreno(),
                const SizedBox(height: 24),
                Semantics(
                  button: true,
                  enabled: !_guardando,
                  focusable: true,
                  label: 'Crear imperio',
                  child: FilledButton.icon(
                    onPressed: _guardando ? null : _crearImperio,
                    icon:
                        _guardando
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.flag),
                    label: Text(_guardando ? 'Creando...' : 'Crear imperio'),
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
