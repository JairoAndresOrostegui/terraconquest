import 'package:flutter/material.dart';

class ImpuestosWidget extends StatelessWidget {
  const ImpuestosWidget({
    super.key,
    required this.valor,
    required this.cargando,
    required this.onChanged,
  });

  final int valor;
  final bool cargando;
  final ValueChanged<int> onChanged;

  String get _descripcion {
    if (valor <= 10) return 'Bajos: crecimiento alto';
    if (valor <= 25) return 'Medios: balanceado';
    return 'Altos: más oro pero menor crecimiento';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Control de impuestos de la ciudad, valor actual $valor por ciento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impuestos: $valor%',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: valor.toDouble(),
            min: 0,
            max: 50,
            divisions: 10,
            label: '$valor%',
            onChanged: cargando ? null : (value) => onChanged(value.toInt()),
          ),
          const SizedBox(height: 4),
          Text(
            _descripcion,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
