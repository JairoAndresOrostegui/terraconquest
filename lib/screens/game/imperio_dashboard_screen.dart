import 'package:flutter/material.dart';

import '../../models/ciudad_model.dart';
import '../../models/imperio_model.dart';
import '../../services/dashboard_imperio_service.dart';
import 'ciudad/ciudad_detalle_screen.dart';
import 'ciudad/fundar_ciudad_screen.dart';
import 'ejercito/ejercito_imperio_screen.dart';
import 'eventos/eventos_imperio_screen.dart';
import 'heroes/comprar_heroe_screen.dart';
import 'rankings/ranking_imperios_screen.dart';

class ImperioDashboardScreen extends StatefulWidget {
  const ImperioDashboardScreen({
    super.key,
    required this.partidaId,
    required this.imperioId,
  });

  final String partidaId;
  final String imperioId;

  @override
  State<ImperioDashboardScreen> createState() => _ImperioDashboardScreenState();
}

class _ImperioDashboardScreenState extends State<ImperioDashboardScreen> {
  final DashboardImperioService _service = DashboardImperioService();

  int _numero(dynamic valor) {
    if (valor is int) return valor;
    if (valor is double) return valor.round();
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  Widget _buildRecurso(String nombre, dynamic valor, dynamic produccion) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Semantics(
          container: true,
          label:
              '$nombre, cantidad ${_numero(valor)}, producción diaria ${_numero(produccion)}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Actual: ${_numero(valor)}'),
              Text('Día: +${_numero(produccion)}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenImperio(ImperioModel imperio) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          container: true,
          label: 'Resumen del imperio ${imperio.nombre}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                imperio.nombre,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  Text('Valor: ${imperio.valor}'),
                  Text('Ranking: ${imperio.ranking}'),
                  Text('Turnos: ${imperio.turnos}'),
                  Text('Fama: ${imperio.fama}'),
                  Text('Índice bélico: ${imperio.indiceBelico}'),
                  Text('Ciudades: ${imperio.totalCiudades}'),
                  Text('Héroes: ${imperio.totalHeroes}'),
                  Text('Población: ${imperio.totalPoblacion}'),
                  Text('Tropas: ${imperio.totalTropas}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecursos(ImperioModel imperio) {
    const recursosPrincipales = [
      'oro',
      'alimentos',
      'agua',
      'madera',
      'piedra',
      'hierro',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recursos',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recursosPrincipales.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 190,
            childAspectRatio: 1.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final key = recursosPrincipales[index];

            return _buildRecurso(
              key,
              imperio.recursos[key],
              imperio.produccionDiaria[key],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCiudadCard(CiudadModel ciudad) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Semantics(
          container: true,
          label: 'Ciudad ${ciudad.nombre}, población ${ciudad.poblacion}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ciudad.nombre,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  Text('Población: ${ciudad.poblacion}'),
                  Text('Moral: ${ciudad.moral}'),
                  Text('Felicidad: ${ciudad.felicidad}'),
                  Text('Higiene: ${ciudad.higiene}'),
                  Text('Corrupción: ${ciudad.corrupcion}'),
                  Text('Impuestos: ${ciudad.impuestosPct}%'),
                  Text('Edificios: ${ciudad.totalEdificios}'),
                ],
              ),
              const SizedBox(height: 10),
              Semantics(
                button: true,
                enabled: true,
                focusable: true,
                label: 'Ver ciudad ${ciudad.nombre}',
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CiudadDetalleScreen(
                          partidaId: widget.partidaId,
                          ciudadId: ciudad.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.location_city),
                  label: const Text('Ver ciudad'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFundarCiudadButton() {
    return Semantics(
      button: true,
      enabled: true,
      focusable: true,
      label: 'Fundar nueva ciudad',
      child: FilledButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FundarCiudadScreen(
                partidaId: widget.partidaId,
                imperioId: widget.imperioId,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Fundar ciudad'),
      ),
    );
  }

  Widget _buildCiudadesHeader() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Ciudades',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        _buildFundarCiudadButton(),
      ],
    );
  }

  Widget _buildCiudades() {
    return StreamBuilder<List<CiudadModel>>(
      stream: _service.observarCiudadesDelImperio(
        partidaId: widget.partidaId,
        imperioId: widget.imperioId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        if (snapshot.hasError) {
          return const Text('No se pudieron cargar las ciudades.');
        }

        final ciudades = snapshot.data ?? [];

        if (ciudades.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCiudadesHeader(),
              const SizedBox(height: 8),
              const Text('Este imperio aún no tiene ciudades.'),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCiudadesHeader(),
            const SizedBox(height: 8),
            ...ciudades.map(_buildCiudadCard),
          ],
        );
      },
    );
  }

  Widget _buildMenuLateral() {
    const opciones = [
      'Tu imperio',
      'Tu ejército',
      'Últimos ataques',
      'Conquistas',
      'Noticias',
      'Ranking de imperios',
      'Ciudades',
      'Héroes',
      'Clanes',
    ];

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            child: Text('Terra Conquest'),
          ),
          ...opciones.map(
            (opcion) => Semantics(
              button: true,
              enabled: true,
              focusable: true,
              label: opcion,
              child: ListTile(
                title: Text(opcion),
                onTap: () {
                  Navigator.pop(context);

                  if (opcion.startsWith('Tu ej')) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EjercitoImperioScreen(
                          partidaId: widget.partidaId,
                          imperioId: widget.imperioId,
                        ),
                      ),
                    );
                    return;
                  }

                  if (opcion == 'Noticias') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventosImperioScreen(
                          partidaId: widget.partidaId,
                          imperioId: widget.imperioId,
                        ),
                      ),
                    );
                    return;
                  }

                  if (opcion == 'Tu ejÃ©rcito') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EjercitoImperioScreen(
                          partidaId: widget.partidaId,
                          imperioId: widget.imperioId,
                        ),
                      ),
                    );
                    return;
                  }

                  if (opcion == 'Ranking de imperios') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RankingImperiosScreen(
                          partidaId: widget.partidaId,
                        ),
                      ),
                    );
                    return;
                  }

                  if (opcion.startsWith('H')) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ComprarHeroeScreen(
                          partidaId: widget.partidaId,
                          imperioId: widget.imperioId,
                        ),
                      ),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$opcion se implementará más adelante.'),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ImperioModel>(
      stream: _service.observarImperio(
        partidaId: widget.partidaId,
        imperioId: widget.imperioId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: Text('No se pudo cargar el imperio.'),
            ),
          );
        }

        final imperio = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(imperio.nombre),
          ),
          drawer: _buildMenuLateral(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildResumenImperio(imperio),
                    const SizedBox(height: 16),
                    _buildRecursos(imperio),
                    const SizedBox(height: 20),
                    _buildCiudades(),
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
