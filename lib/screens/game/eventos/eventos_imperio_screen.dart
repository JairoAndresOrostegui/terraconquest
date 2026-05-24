import 'package:flutter/material.dart';

import '../../../models/evento_model.dart';
import '../../../services/eventos_service.dart';

class EventosImperioScreen extends StatefulWidget {
  const EventosImperioScreen({
    super.key,
    required this.partidaId,
    required this.imperioId,
  });

  final String partidaId;
  final String imperioId;

  @override
  State<EventosImperioScreen> createState() => _EventosImperioScreenState();
}

class _EventosImperioScreenState extends State<EventosImperioScreen> {
  final EventosService _service = EventosService();
  bool _globales = false;

  IconData _iconoEvento(String tipo) {
    switch (tipo) {
      case 'prosperidad':
        return Icons.trending_up;
      case 'rebelion':
        return Icons.warning;
      case 'plaga':
        return Icons.sick;
      case 'corrupcion':
        return Icons.gavel;
      case 'delincuencia':
        return Icons.report;
      case 'sistema':
        return Icons.info;
      case 'conquista':
        return Icons.flag;
      default:
        return Icons.article;
    }
  }

  String _fecha(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';

    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '${fecha.year}-$mes-$dia $hora:$minuto';
  }

  Widget _buildEvento(EventoModel evento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        container: true,
        label: '${evento.titulo}. ${evento.descripcion}. Día ${evento.dia}',
        child: ListTile(
          leading: Icon(_iconoEvento(evento.tipo)),
          title: Text(evento.titulo),
          subtitle: Text(
            '${evento.descripcion}\n'
            'Día: ${evento.dia} | ${_fecha(evento.creadoEn)}',
          ),
          isThreeLine: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = _globales
        ? _service.observarEventosGlobales(partidaId: widget.partidaId)
        : _service.observarEventosImperio(
            partidaId: widget.partidaId,
            imperioId: widget.imperioId,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias y eventos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Semantics(
              button: true,
              focusable: true,
              label: _globales
                  ? 'Mostrando eventos globales'
                  : 'Mostrando eventos de mi imperio',
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Mi imperio'),
                    icon: Icon(Icons.account_balance),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Globales'),
                    icon: Icon(Icons.public),
                  ),
                ],
                selected: {_globales},
                onSelectionChanged: (value) {
                  setState(() {
                    _globales = value.first;
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<EventoModel>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('No se pudieron cargar los eventos.'),
                  );
                }

                final eventos = snapshot.data ?? [];

                if (eventos.isEmpty) {
                  return const Center(
                    child: Text('No hay eventos para mostrar.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    return _buildEvento(eventos[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
