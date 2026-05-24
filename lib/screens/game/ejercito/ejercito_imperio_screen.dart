import 'package:flutter/material.dart';

import '../../../models/tropa_ciudad_model.dart';
import '../../../services/ejercito_service.dart';
import '../tropas/mover_tropas_screen.dart';

class EjercitoImperioScreen extends StatefulWidget {
  const EjercitoImperioScreen({
    super.key,
    required this.partidaId,
    required this.imperioId,
  });

  final String partidaId;
  final String imperioId;

  @override
  State<EjercitoImperioScreen> createState() => _EjercitoImperioScreenState();
}

class _EjercitoImperioScreenState extends State<EjercitoImperioScreen> {
  final EjercitoService _service = EjercitoService();

  late Future<List<CiudadConTropas>> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<List<CiudadConTropas>> _cargar() {
    return _service.obtenerEjercitoImperio(
      partidaId: widget.partidaId,
      imperioId: widget.imperioId,
    );
  }

  Future<void> _recargar() async {
    setState(() {
      _future = _cargar();
    });

    await _future;
  }

  Widget _buildTropa(TropaCiudadModel tropa) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        container: true,
        label:
            '${tropa.nombre}, nivel ${tropa.nivel}, cantidad ${tropa.cantidad}, niveles totales ${tropa.nivelesTotales}',
        child: ListTile(
          leading: CircleAvatar(
            child: Text('N${tropa.nivel}'),
          ),
          title: Text(tropa.nombre),
          subtitle: Text(
            'Cantidad: ${tropa.cantidad} | Niveles: ${tropa.nivelesTotales}\n'
            'ATQ ${tropa.ataque} | DEF ${tropa.defensa} | DAÑO ${tropa.danio} | VIDA ${tropa.vida}\n'
            'Ataque: ${tropa.tipoAtaque} | Defensa: ${tropa.tipoDefensa} | Magia: ${tropa.tipoMagia}',
          ),
          isThreeLine: true,
          trailing: Text(tropa.asignacion),
        ),
      ),
    );
  }

  Widget _buildCiudad(CiudadConTropas item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        container: true,
        label:
            'Ciudad ${item.ciudad.nombre}, tropas ${item.totalTropas}, niveles ${item.totalNiveles}',
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(item.ciudad.nombre),
          subtitle: Text(
            'Población: ${item.ciudad.poblacion} | '
            'Tropas: ${item.totalTropas} | '
            'Niveles: ${item.totalNiveles}',
          ),
          childrenPadding: const EdgeInsets.all(12),
          children: [
            if (item.tropas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Esta ciudad no tiene tropas.'),
              )
            else
              ...item.tropas.map(_buildTropa),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu ejército'),
        actions: [
          Semantics(
            button: true,
            enabled: true,
            focusable: true,
            label: 'Mover tropas',
            child: IconButton(
              tooltip: 'Mover tropas',
              onPressed: () async {
                final resultado = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => MoverTropasScreen(
                      partidaId: widget.partidaId,
                      imperioId: widget.imperioId,
                    ),
                  ),
                );

                if (resultado == true) {
                  await _recargar();
                }
              },
              icon: const Icon(Icons.swap_horiz),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<CiudadConTropas>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudo cargar el ejército.'),
            );
          }

          final ciudades = snapshot.data ?? [];

          if (ciudades.isEmpty) {
            return const Center(
              child: Text('No tienes ciudades para mostrar ejército.'),
            );
          }

          final totalTropas = ciudades.fold<int>(
            0,
            (total, item) => total + item.totalTropas,
          );
          final totalNiveles = ciudades.fold<int>(
            0,
            (total, item) => total + item.totalNiveles,
          );

          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Semantics(
                      container: true,
                      label:
                          'Resumen del ejército, tropas $totalTropas, niveles $totalNiveles',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen del ejército',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Total tropas: $totalTropas'),
                          Text('Total niveles de tropa: $totalNiveles'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...ciudades.map(_buildCiudad),
              ],
            ),
          );
        },
      ),
    );
  }
}
