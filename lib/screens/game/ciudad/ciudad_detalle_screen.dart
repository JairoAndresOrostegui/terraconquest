import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../services/ciudad_service.dart';
import '../../../services/tropas_service.dart';
import 'widgets/impuestos_widget.dart';

class CiudadDetalleScreen extends StatefulWidget {
  const CiudadDetalleScreen({
    super.key,
    required this.partidaId,
    required this.ciudadId,
  });

  final String partidaId;
  final String ciudadId;

  @override
  State<CiudadDetalleScreen> createState() => _CiudadDetalleScreenState();
}

class _CiudadDetalleScreenState extends State<CiudadDetalleScreen> {
  final CiudadService _ciudadService = CiudadService();
  final TropasService _tropasService = TropasService();

  bool _procesando = false;
  bool _guardandoImpuestos = false;

  int _numero(dynamic valor) {
    if (valor is int) return valor;
    if (valor is double) return valor.round();
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _observarCiudad() {
    return FirebaseFirestore.instance
        .collection('partidas')
        .doc(widget.partidaId)
        .collection('ciudades')
        .doc(widget.ciudadId)
        .snapshots();
  }

  Future<void> _mejorarEdificio(String edificioId) async {
    if (_procesando) return;

    setState(() => _procesando = true);

    try {
      final result = await _ciudadService.mejorarEdificio(
        partidaId: widget.partidaId,
        ciudadId: widget.ciudadId,
        edificioId: edificioId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Edificio mejorado a nivel ${result['nuevoNivel']}.'),
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ??
                'No se pudo mejorar el edificio. Revisa tus recursos y turnos.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo mejorar el edificio. Revisa tus recursos y turnos.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Future<void> _cambiarImpuestos(int impuestosPct) async {
    if (_guardandoImpuestos) return;

    setState(() => _guardandoImpuestos = true);

    try {
      await _ciudadService.cambiarImpuestos(
        partidaId: widget.partidaId,
        ciudadId: widget.ciudadId,
        impuestosPct: impuestosPct,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impuestos actualizados a $impuestosPct%.')),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'No se pudieron actualizar los impuestos.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron actualizar los impuestos.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardandoImpuestos = false);
      }
    }
  }

  Widget _buildHeader(Map<String, dynamic> ciudad) {
    final nombre = ciudad['nombre']?.toString() ?? 'Ciudad';
    final poblacion = _numero(ciudad['poblacion']);
    final estado = ciudad['estado']?.toString() ?? 'activa';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          container: true,
          label:
              'Resumen de ciudad $nombre, población $poblacion, estado $estado',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  Text('Estado: $estado'),
                  Text('Población: $poblacion'),
                  Text('Región: ${ciudad['regionId'] ?? ''}'),
                  Text('Terreno: ${ciudad['terrenoId'] ?? ''}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoSocial(Map<String, dynamic> ciudad) {
    final items = {
      'Moral': ciudad['moral'],
      'Felicidad': ciudad['felicidad'],
      'Higiene': ciudad['higiene'],
      'Corrupción': ciudad['corrupcion'],
      'Desempleo': ciudad['desempleo'],
      'Religión': ciudad['religion'],
      'Cultura': ciudad['cultura'],
      'Impuestos': ciudad['impuestosPct'],
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          container: true,
          label: 'Estado social de la ciudad',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estado social',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: items.entries.map((entry) {
                  final suffix = entry.key == 'Impuestos' ? '%' : '';
                  return Chip(
                    label: Text('${entry.key}: ${_numero(entry.value)}$suffix'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              ImpuestosWidget(
                valor: _numero(ciudad['impuestosPct']),
                cargando: _guardandoImpuestos,
                onChanged: _cambiarImpuestos,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProduccion(Map<String, dynamic> ciudad) {
    final produccion =
        Map<String, dynamic>.from(ciudad['produccionDiaria'] ?? {});
    final consumo = Map<String, dynamic>.from(ciudad['consumoDiario'] ?? {});

    const recursos = [
      'oro',
      'alimentos',
      'agua',
      'madera',
      'piedra',
      'hierro',
      'herramientas',
      'armas',
      'bloques',
      'tablas',
      'mithril',
      'cristal',
      'plata',
      'reliquias',
      'gemas',
      'joyas',
      'mana',
      'karma',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          container: true,
          label: 'Producción diaria y consumo de la ciudad',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Producción diaria',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recursos.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 4 : 2,
                      childAspectRatio: isWide ? 3.2 : 2.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final recurso = recursos[index];
                      final producido = _numero(produccion[recurso]);
                      final consumido = _numero(consumo[recurso]);
                      final neto = producido - consumido;

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Semantics(
                          label:
                              '$recurso, produce $producido, consume $consumido, neto $neto',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recurso,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Produce: +$producido'),
                              Text('Consume: -$consumido'),
                              Text('Neto: $neto'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEdificios(Map<String, dynamic> ciudad) {
    final edificios = Map<String, dynamic>.from(ciudad['edificios'] ?? {});

    const orden = [
      'castillo',
      'cuartel',
      'muralla',
      'armeria',
      'foso',
      'minaOro',
      'minaPlata',
      'minaHierro',
      'minaPiedra',
      'minaMithril',
      'aserradero',
      'cultivos',
      'pozos',
      'mercado',
      'mercadoNegro',
      'taller',
      'forjaHierro',
      'forjaMithril',
      'joyeria',
      'camaraCristal',
      'cantera',
      'carpinteria',
      'monumentos',
      'acueducto',
      'almacen',
      'coliseo',
      'burdeles',
      'escuela',
      'templo',
      'santuario',
      'universidad',
      'torreMagica',
    ];

    final visibles = orden.where(edificios.containsKey).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          container: true,
          label: 'Lista de edificios de la ciudad',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edificios',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (visibles.isEmpty)
                const Text('No hay edificios registrados.')
              else
                ...visibles.map((key) {
                  final nivel = _numero(edificios[key]);
                  final nombre = _formatearNombreEdificio(key);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.account_balance),
                    title: Text(nombre),
                    subtitle: Text('Nivel $nivel'),
                    trailing: Semantics(
                      button: true,
                      enabled: !_procesando,
                      focusable: true,
                      label: 'Mejorar $nombre',
                      child: OutlinedButton(
                        onPressed:
                            _procesando ? null : () => _mejorarEdificio(key),
                        child: const Text('Mejorar'),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTropas(Map<String, dynamic> ciudad) {
    final nivelesActuales = _numero(ciudad['nivelesTropasDefensaActuales']);
    final nivelesMinimos = _numero(ciudad['nivelesTropasDefensaMinimos']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          container: true,
          label: 'Tropas de la ciudad',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tropas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  Text('Niveles defensa: $nivelesActuales'),
                  Text('Mínimo recomendado: $nivelesMinimos'),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder(
                stream: _tropasService.observarTropasCiudad(
                  partidaId: widget.partidaId,
                  ciudadId: widget.ciudadId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return const Text('No se pudieron cargar las tropas.');
                  }

                  final tropas = snapshot.data ?? [];

                  if (tropas.isEmpty) {
                    return const Text('No hay tropas en esta ciudad.');
                  }

                  return Column(
                    children: tropas.map((tropa) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.shield),
                        title: Text(tropa.nombre),
                        subtitle: Text(
                          'Nivel ${tropa.nivel} | ${tropa.asignacion} | niveles totales ${tropa.nivelesTotales}',
                        ),
                        trailing: Text('${tropa.cantidad}'),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatearNombreEdificio(String key) {
    if (key.isEmpty) return key;

    final texto = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );

    return texto[0].toUpperCase() + texto.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _observarCiudad(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(
              child: Text('No se pudo cargar la ciudad.'),
            ),
          );
        }

        final ciudad = snapshot.data!.data()!;

        return Scaffold(
          appBar: AppBar(
            title: Text(ciudad['nombre']?.toString() ?? 'Ciudad'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(ciudad),
                    const SizedBox(height: 12),
                    _buildEstadoSocial(ciudad),
                    const SizedBox(height: 12),
                    _buildProduccion(ciudad),
                    const SizedBox(height: 12),
                    _buildEdificios(ciudad),
                    const SizedBox(height: 12),
                    _buildTropas(ciudad),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
