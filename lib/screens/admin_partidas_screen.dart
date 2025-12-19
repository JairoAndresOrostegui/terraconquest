import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminPartidasScreen extends StatefulWidget {
  const AdminPartidasScreen({super.key});

  @override
  State<AdminPartidasScreen> createState() => _AdminPartidasScreenState();
}

class _AdminPartidasScreenState extends State<AdminPartidasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _horasProteccionController = TextEditingController();
  final _maxImperiosController = TextEditingController();
  final _tiempoInscripcionController = TextEditingController();
  String? _mapaSeleccionado;
  List<String> _mapasDisponibles = [];
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _idEditando;

  @override
  void initState() {
    super.initState();
    _cargarMapas();
  }

  Future<void> _cargarMapas() async {
    final snapshot = await FirebaseFirestore.instance.collection('mapas').get();
    setState(() {
      _mapasDisponibles = snapshot.docs.map((doc) => doc['nombre'].toString()).toList();
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nombreController.clear();
    _horasProteccionController.clear();
    _maxImperiosController.clear();
    _tiempoInscripcionController.clear();
    _mapaSeleccionado = null;
    _fechaInicio = null;
    _fechaFin = null;
    _idEditando = null;
  }

  Future<void> _mostrarFormulario({DocumentSnapshot? partida}) async {
    if (partida != null) {
      final data = partida.data() as Map<String, dynamic>;
      _idEditando = partida.id;
      _nombreController.text = data['nombre'] ?? '';
      _mapaSeleccionado = data['mapa'] ?? '';
      _horasProteccionController.text = (data['horasProteccion'] ?? '').toString();
      _maxImperiosController.text = (data['maxImperios'] ?? '').toString();
      _tiempoInscripcionController.text = (data['tiempoInscripcion'] ?? '').toString();
      _fechaInicio = (data['fechaInicio'] as Timestamp?)?.toDate();
      _fechaFin = (data['fechaFin'] as Timestamp?)?.toDate();
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_idEditando == null ? 'Crear Partida' : 'Editar Partida'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _mapaSeleccionado,
                  decoration: const InputDecoration(labelText: 'Mapa'),
                  items: _mapasDisponibles.map((nombre) {
                    return DropdownMenuItem(
                      value: nombre,
                      child: Text(nombre),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _mapaSeleccionado = value),
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _horasProteccionController,
                  decoration: const InputDecoration(labelText: 'Horas de protección'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _maxImperiosController,
                  decoration: const InputDecoration(labelText: 'Máx. Imperios'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _tiempoInscripcionController,
                  decoration: const InputDecoration(labelText: 'Días de inscripción antes de iniciar'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_fechaInicio != null
                      ? 'Inicio: ${DateFormat.yMd().format(_fechaInicio!)}'
                      : 'Seleccionar fecha de inicio'),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _fechaInicio ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _fechaInicio = date);
                    }
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_fechaFin != null
                      ? 'Fin: ${DateFormat.yMd().format(_fechaFin!)}'
                      : 'Seleccionar fecha de fin'),
                  onPressed: () async {
                    final firstDate = _fechaInicio ?? DateTime.now();
                    final initial = (_fechaFin != null && !_fechaFin!.isBefore(firstDate))
                        ? _fechaFin!
                        : firstDate;
                    final date = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: firstDate,
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _fechaFin = date);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() != true) return;
              if (_fechaInicio == null || _fechaFin == null) return;
              if (_fechaInicio!.isAfter(_fechaFin!)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La fecha de inicio no puede ser posterior a la fecha fin.')),
                );
                return;
              }

              final partidaData = {
                'nombre': _nombreController.text.trim(),
                'mapa': _mapaSeleccionado,
                'horasProteccion': int.parse(_horasProteccionController.text),
                'maxImperios': int.parse(_maxImperiosController.text),
                'tiempoInscripcion': int.parse(_tiempoInscripcionController.text),
                'fechaInicio': _fechaInicio,
                'fechaFin': _fechaFin,
                'estado': 'futura',
              };

              final partidas = FirebaseFirestore.instance.collection('partidas');

              if (_idEditando != null) {
                await partidas.doc(_idEditando).update(partidaData);
              } else {
                await partidas.add(partidaData);
              }

              if (mounted) Navigator.of(context).pop();
              _resetForm();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarPartida(String id, DateTime fechaInicio) async {
    if (fechaInicio.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede eliminar una partida que ya inició.')),
      );
      return;
    }
    await FirebaseFirestore.instance.collection('partidas').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Partidas'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('partidas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final partidas = snapshot.data?.docs ?? [];

          if (partidas.isEmpty) {
            return const Center(child: Text('No hay partidas registradas.'));
          }

          return ListView.builder(
            itemCount: partidas.length,
            itemBuilder: (context, index) {
              final partida = partidas[index];
              final fechaInicio = (partida['fechaInicio'] as Timestamp).toDate();
              final fechaFin = (partida['fechaFin'] as Timestamp).toDate();

              return ListTile(
                title: Text(partida['nombre'] ?? ''),
                subtitle: Text('Mapa: ${partida['mapa']}\nInicio: ${DateFormat.yMd().format(fechaInicio)} | Fin: ${DateFormat.yMd().format(fechaFin)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _mostrarFormulario(partida: partida),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _eliminarPartida(partida.id, fechaInicio),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}