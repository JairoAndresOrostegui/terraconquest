import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AdminMapasScreen extends StatefulWidget {
  const AdminMapasScreen({super.key});

  @override
  State<AdminMapasScreen> createState() => _AdminMapasScreenState();
}

class _AdminMapasScreenState extends State<AdminMapasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  List<String> _regionesDisponibles = [];
  List<String> _regionesSeleccionadas = [];
  Uint8List? _imagenBytes;
  String? _imagenUrl;
  String? _idEditando;

  @override
  void initState() {
    super.initState();
    _cargarRegiones();
  }

  Future<void> _cargarRegiones() async {
    final snapshot = await FirebaseFirestore.instance.collection('regiones').get();
    setState(() {
      _regionesDisponibles = snapshot.docs.map((doc) => doc['nombre'].toString()).toList();
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nombreController.clear();
    _descripcionController.clear();
    _regionesSeleccionadas = [];
    _imagenBytes = null;
    _imagenUrl = null;
    _idEditando = null;
  }

  Future<void> _seleccionarImagen() async {
    final resultado = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (resultado != null && resultado.files.isNotEmpty) {
      setState(() {
        _imagenBytes = resultado.files.first.bytes;
      });
    }
  }

  Future<void> _mostrarFormulario({DocumentSnapshot? mapa}) async {
    if (mapa != null) {
      _idEditando = mapa.id;
      _nombreController.text = mapa['nombre'];
      _descripcionController.text = mapa['descripcion'];
      _regionesSeleccionadas = List<String>.from(mapa['regiones'] ?? []);
      _imagenUrl = mapa['imagenUrl'];
    } else {
      _idEditando = null;
      _nombreController.clear();
      _descripcionController.clear();
      _regionesSeleccionadas = [];
      _imagenBytes = null;
      _imagenUrl = null;
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_idEditando == null ? 'Crear Mapa' : 'Editar Mapa'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre del mapa'),
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                const Text('Regiones disponibles:'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _regionesDisponibles.where((r) => !_regionesSeleccionadas.contains(r)).map((region) {
                    return ActionChip(
                      label: Text(region),
                      backgroundColor: const Color.fromARGB(255, 100, 60, 1),
                      onPressed: () {
                        setState(() {
                          _regionesSeleccionadas.add(region);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                const Text('Regiones seleccionadas:'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _regionesSeleccionadas.map((region) {
                    return Chip(
                      label: Text(region),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () {
                        setState(() {
                          _regionesSeleccionadas.remove(region);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _seleccionarImagen,
                  child: const Text('Seleccionar imagen del mapa'),
                ),
                const SizedBox(height: 10),
                if (_imagenBytes != null)
                  Image.memory(_imagenBytes!, height: 120)
                else if (_imagenUrl != null)
                  Image.network(_imagenUrl!, height: 120),
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

              String? url = _imagenUrl;
              if (_imagenBytes != null) {
                final nombreArchivo = '${DateTime.now().millisecondsSinceEpoch}_${_nombreController.text.trim()}';
                final ref = FirebaseStorage.instance.ref().child('mapas/$nombreArchivo.png');
                await ref.putData(_imagenBytes!);
                url = await ref.getDownloadURL();
              }

              final mapaData = {
                'nombre': _nombreController.text.trim(),
                'descripcion': _descripcionController.text.trim(),
                'regiones': _regionesSeleccionadas,
                'imagenUrl': url,
              };

              final mapas = FirebaseFirestore.instance.collection('mapas');

              if (_idEditando != null) {
                await mapas.doc(_idEditando).update(mapaData);
              } else {
                await mapas.add(mapaData);
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

  Future<void> _eliminarMapa(String id) async {
    await FirebaseFirestore.instance.collection('mapas').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Mapas'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('mapas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final mapas = snapshot.data?.docs ?? [];

          if (mapas.isEmpty) {
            return const Center(child: Text('No hay mapas registrados.'));
          }

          return ListView.builder(
            itemCount: mapas.length,
            itemBuilder: (context, index) {
              final mapa = mapas[index];
              final regiones = List<String>.from(mapa['regiones'] ?? []);
              final imagen = mapa['imagenUrl'];

              return ListTile(
                leading: imagen != null
                    ? Image.network(imagen, height: 40, width: 40, fit: BoxFit.cover)
                    : null,
                title: Text(mapa['nombre'] ?? ''),
                subtitle: Text('${mapa['descripcion'] ?? ''}\nRegiones: ${regiones.join(", ")}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _mostrarFormulario(mapa: mapa),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _eliminarMapa(mapa.id),
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
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
