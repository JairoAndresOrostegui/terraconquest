import 'package:flutter/material.dart';

import '../../../models/ranking_imperio_model.dart';
import '../../../services/ranking_service.dart';

class RankingImperiosScreen extends StatelessWidget {
  RankingImperiosScreen({
    super.key,
    required this.partidaId,
    RankingService? service,
  }) : _service = service ?? RankingService();

  final String partidaId;
  final RankingService _service;

  IconData _iconoMovimiento(int movimiento) {
    if (movimiento > 0) return Icons.arrow_upward;
    if (movimiento < 0) return Icons.arrow_downward;
    return Icons.remove;
  }

  String _textoMovimiento(int movimiento) {
    if (movimiento > 0) return '+$movimiento';
    return '$movimiento';
  }

  Widget _buildItem(RankingImperioModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        container: true,
        label:
            'Ranking ${item.ranking}, imperio ${item.nombreImperio}, valor ${item.valor}',
        child: ListTile(
          leading: CircleAvatar(
            child: Text('${item.ranking}'),
          ),
          title: Text(item.nombreImperio),
          subtitle: Text(
            'Valor: ${item.valor}\n'
            'Raza: ${item.razaId} | Clan: ${item.tagClan ?? 'Sin clan'}\n'
            'Ciudades: ${item.ciudades} | Héroes: ${item.heroes}',
          ),
          isThreeLine: true,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconoMovimiento(item.movimiento)),
              Text(_textoMovimiento(item.movimiento)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking de imperios'),
      ),
      body: StreamBuilder<List<RankingImperioModel>>(
        stream: _service.observarRankingImperios(partidaId: partidaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudo cargar el ranking.'),
            );
          }

          final ranking = snapshot.data ?? [];

          if (ranking.isEmpty) {
            return const Center(
              child: Text(
                'El ranking aún no está disponible. Ejecuta el paso de día para generarlo.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ranking.length,
            itemBuilder: (context, index) {
              return _buildItem(ranking[index]);
            },
          );
        },
      ),
    );
  }
}
