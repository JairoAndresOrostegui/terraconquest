import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../models/region_model.dart';
import '../../../services/catalogo_juego_service.dart';
import '../../../services/heroes_service.dart';

class ComprarHeroeScreen extends StatefulWidget {
  const ComprarHeroeScreen({
    super.key,
    required this.partidaId,
    required this.imperioId,
  });

  final String partidaId;
  final String imperioId;

  @override
  State<ComprarHeroeScreen> createState() => _ComprarHeroeScreenState();
}

class _ComprarHeroeScreenState extends State<ComprarHeroeScreen> {
  final HeroesService _heroesService = HeroesService();
  final CatalogoJuegoService _catalogoService = CatalogoJuegoService();
  final TextEditingController _nombreController = TextEditingController();

  bool _cargandoRegiones = true;
  bool _comprando = false;
  List<RegionModel> _regiones = [];
  RegionModel? _regionSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarRegiones();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _cargarRegiones() async {
    try {
      final regiones = await _catalogoService.obtenerRegionesDePartida(
        widget.partidaId,
      );

      if (!mounted) return;

      setState(() {
        _regiones = regiones;
        _cargandoRegiones = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoRegiones = false);
      _mensaje('No se pudieron cargar las regiones.');
    }
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _comprar(DocumentSnapshot<Map<String, dynamic>> oferta) async {
    final nombre = _nombreController.text.trim();

    if (nombre.length < 3 || nombre.length > 30) {
      _mensaje('El nombre del héroe debe tener entre 3 y 30 caracteres.');
      return;
    }

    if (_regionSeleccionada == null) {
      _mensaje('Selecciona una región inicial.');
      return;
    }

    setState(() => _comprando = true);

    try {
      await _heroesService.comprarHeroe(
        partidaId: widget.partidaId,
        imperioId: widget.imperioId,
        ofertaHeroeId: oferta.id,
        nombreHeroe: nombre,
        regionId: _regionSeleccionada!.id,
      );

      if (!mounted) return;

      _mensaje('Héroe comprado correctamente.');
      Navigator.pop(context, true);
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      _mensaje(error.message ?? 'No se pudo comprar el héroe.');
    } catch (_) {
      if (!mounted) return;
      _mensaje('No se pudo comprar el héroe. Revisa oro, nombre y disponibilidad.');
    } finally {
      if (mounted) {
        setState(() => _comprando = false);
      }
    }
  }

  Widget _buildOferta(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final clase = data['clase']?.toString() ?? '';
    final nivel = (data['nivel'] as num?)?.toInt() ?? 0;
    final precioOro = (data['precioOro'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Semantics(
          container: true,
          label: 'Héroe $clase nivel $nivel, precio $precioOro oro',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$clase - Nivel $nivel',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text('Ataque: ${data['ataque'] ?? 0}'),
                  Text('Defensa: ${data['defensa'] ?? 0}'),
                  Text('Daño: ${data['danio'] ?? 0}'),
                  Text('Vida: ${data['vida'] ?? 0}'),
                  Text('Velocidad: ${data['velocidad'] ?? 0}'),
                  Text('Moral: ${data['moral'] ?? 0}'),
                  Text('Precio: $precioOro oro'),
                ],
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                enabled: !_comprando,
                focusable: true,
                label: 'Comprar héroe $clase nivel $nivel',
                child: FilledButton(
                  onPressed: _comprando ? null : () => _comprar(doc),
                  child: const Text('Comprar este héroe'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoRegiones) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprar héroe'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Semantics(
                  textField: true,
                  focusable: true,
                  label: 'Nombre del héroe',
                  child: TextField(
                    controller: _nombreController,
                    maxLength: 30,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del héroe',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  focusable: true,
                  label: 'Región inicial del héroe',
                  child: DropdownButtonFormField<RegionModel>(
                    initialValue: _regionSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Región inicial',
                      border: OutlineInputBorder(),
                    ),
                    items: _regiones.map((region) {
                      return DropdownMenuItem<RegionModel>(
                        value: region,
                        child: Text('${region.numero} - ${region.nombre}'),
                      );
                    }).toList(),
                    onChanged: _comprando
                        ? null
                        : (value) {
                            setState(() {
                              _regionSeleccionada = value;
                            });
                          },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _heroesService.observarHeroesMercado(
                partidaId: widget.partidaId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('No se pudieron cargar los héroes disponibles.'),
                  );
                }

                final ofertas = snapshot.data?.docs ?? [];

                if (ofertas.isEmpty) {
                  return const Center(
                    child: Text('No hay héroes disponibles por ahora.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ofertas.length,
                  itemBuilder: (context, index) => _buildOferta(ofertas[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
