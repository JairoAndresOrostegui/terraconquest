import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AdminRegionesScreen extends StatefulWidget {
  const AdminRegionesScreen({super.key});

  @override
  State<AdminRegionesScreen> createState() => _AdminRegionesScreenState();
}

class _AdminRegionesScreenState extends State<AdminRegionesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _bonoRegionController = TextEditingController();
  List<String> _terrenosDisponibles = [];
  List<String> _terrenosSeleccionados = [];
  Uint8List? _imagenBytes;
  String? _imagenUrl;
  String? _idEditando;

  @override
  void initState() {
    super.initState();
    _cargarTerrenos();
  }

  Future<void> _cargarTerrenos() async {
    final snapshot = await FirebaseFirestore.instance.collection('terrenos').get();
    setState(() {
      _terrenosDisponibles = snapshot.docs.map((doc) => doc['nombre'].toString()).toList();
    });
  }

  Future<void> _seleccionarImagen() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (resultado != null && resultado.files.isNotEmpty) {
      setState(() {
        _imagenBytes = resultado.files.first.bytes;
      });
    }
  }

  Future<void> _mostrarFormulario({DocumentSnapshot? region}) async {
    if (region != null) {
      _idEditando = region.id;
      _nombreController.text = region['nombre'];
      _bonoRegionController.text = region['bonoRegion']?.toString() ?? '';
      _imagenUrl = region['imagenUrl'];
      _terrenosSeleccionados = List<String>.from(region['terrenos'] ?? []);
    } else {
      _idEditando = null;
      _nombreController.clear();
      _bonoRegionController.clear();
      _terrenosSeleccionados = [];
      _imagenBytes = null;
      _imagenUrl = null;
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_idEditando == null ? 'Crear Región' : 'Editar Región'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre de la región'),
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _bonoRegionController,
                  decoration: const InputDecoration(labelText: 'Bono de la región'),
                ),
                const SizedBox(height: 10),
                const Text('Terrenos asociados:'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _terrenosDisponibles
                      .where((terreno) => !_terrenosSeleccionados.contains(terreno))
                      .map((terreno) {
                    return ActionChip(
                      label: Text(terreno),
                      backgroundColor: const Color.fromARGB(255, 19, 110, 1),
                      onPressed: () {
                        setState(() {
                          _terrenosSeleccionados.add(terreno);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                const Text('Terrenos seleccionados:'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _terrenosSeleccionados.map((terreno) {
                    return Chip(
                      label: Text(terreno),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () {
                        setState(() {
                          _terrenosSeleccionados.remove(terreno);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _seleccionarImagen,
                  child: const Text('Seleccionar imagen'),
                ),
                const SizedBox(height: 10),
                if (_imagenBytes != null)
                  Image.memory(_imagenBytes!, height: 100)
                else if (_imagenUrl != null)
                  Image.network(_imagenUrl!, height: 100),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              String? url = _imagenUrl;
              if (_imagenBytes != null) {
                final nombreArchivo = '${DateTime.now().millisecondsSinceEpoch}_${_nombreController.text.trim()}';
                final ref = FirebaseStorage.instance.ref().child('regiones/$nombreArchivo.png');
                await ref.putData(_imagenBytes!);
                url = await ref.getDownloadURL();
              }

              final regionData = {
                'nombre': _nombreController.text.trim(),
                'bonoRegion': _bonoRegionController.text.trim(),
                'terrenos': _terrenosSeleccionados,
                'imagenUrl': url,
              };

              final regiones = FirebaseFirestore.instance.collection('regiones');
              if (_idEditando != null) {
                await regiones.doc(_idEditando).update(regionData);
              } else {
                await regiones.add(regionData);
              }

              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarRegion(String id) async {
    await FirebaseFirestore.instance.collection('regiones').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRUD de Regiones')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('regiones').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final regiones = snapshot.data?.docs ?? [];

          if (regiones.isEmpty) {
            return const Center(child: Text('No hay regiones creadas.'));
          }

          return ListView.builder(
            itemCount: regiones.length,
            itemBuilder: (context, index) {
              final region = regiones[index];
              final nombre = region['nombre'];
              final terrenos = List<String>.from(region['terrenos'] ?? []);
              final bono = region['bonoRegion'] ?? '';
              final imagen = region['imagenUrl'];

              return ListTile(
                leading: imagen != null
                    ? Image.network(imagen, height: 40, width: 40, fit: BoxFit.cover)
                    : null,
                title: Text(nombre),
                subtitle: Text('Terrenos: ${terrenos.join(", ")}\nBono región: $bono'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _mostrarFormulario(region: region),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _eliminarRegion(region.id),
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
