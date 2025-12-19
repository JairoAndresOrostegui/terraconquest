import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AdminRazasScreen extends StatefulWidget {
  const AdminRazasScreen({super.key});

  @override
  State<AdminRazasScreen> createState() => _AdminRazasScreenState();
}

class _AdminRazasScreenState extends State<AdminRazasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  List<String> _ventajas = [];
  List<String> _desventajas = [];
  File? _mobileImage;
  Uint8List? _webImageBytes;
  String? _imagenUrl;
  String? _idEditando;

  void _resetForm() {
    _formKey.currentState?.reset();
    _nombreController.clear();
    _ventajas = [];
    _desventajas = [];
    _mobileImage = null;
    _webImageBytes = null;
    _imagenUrl = null;
    _idEditando = null;
  }

  Future<void> _seleccionarImagen() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      if (kIsWeb) {
        _webImageBytes = result.files.first.bytes;
      } else {
        _mobileImage = File(result.files.single.path!);
      }
      setState(() {});
    }
  }

  Future<void> _mostrarFormulario({DocumentSnapshot? raza}) async {
    if (raza != null) {
      final data = raza.data() as Map<String, dynamic>;
      _idEditando = raza.id;
      _nombreController.text = data['nombre'] ?? '';
      _imagenUrl = data['imagen'] ?? '';
      _ventajas = List<String>.from(data['ventajas'] ?? []);
      _desventajas = List<String>.from(data['desventajas'] ?? []);
    }

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(_idEditando == null ? 'Crear Raza' : 'Editar Raza'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _seleccionarImagen,
                        child: const Text('Seleccionar Imagen'),
                      ),
                      const SizedBox(height: 10),
                      if (_webImageBytes != null)
                        Image.memory(_webImageBytes!, height: 100)
                      else if (_mobileImage != null)
                        Image.file(_mobileImage!, height: 100)
                      else if (_imagenUrl != null)
                        Image.network(_imagenUrl!, height: 100),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ventajas'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setStateDialog(() {
                                _ventajas.add('');
                              });
                            },
                          ),
                        ],
                      ),
                      ..._ventajas.asMap().entries.map((entry) {
                        final i = entry.key;
                        return TextFormField(
                          initialValue: entry.value,
                          decoration:
                              InputDecoration(labelText: 'Ventaja ${i + 1}'),
                          onChanged: (value) => _ventajas[i] = value,
                        );
                      }).toList(),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Desventajas'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setStateDialog(() {
                                _desventajas.add('');
                              });
                            },
                          ),
                        ],
                      ),
                      ..._desventajas.asMap().entries.map((entry) {
                        final i = entry.key;
                        return TextFormField(
                          initialValue: entry.value,
                          decoration:
                              InputDecoration(labelText: 'Desventaja ${i + 1}'),
                          onChanged: (value) => _desventajas[i] = value,
                        );
                      }).toList(),
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
                    final storage = FirebaseStorage.instance.ref();
                    String url = _imagenUrl ?? '';
                    if (_webImageBytes != null || _mobileImage != null) {
                      final nombreArchivo = DateTime.now().millisecondsSinceEpoch.toString();
                      final imagenRef = storage.child('razas/$nombreArchivo.jpg');
                      await imagenRef.putData(_webImageBytes ?? await _mobileImage!.readAsBytes());
                      url = await imagenRef.getDownloadURL();
                    }
                    final razaData = {
                      'nombre': _nombreController.text.trim(),
                      'imagen': url,
                      'ventajas': _ventajas,
                      'desventajas': _desventajas,
                    };
                    final razas = FirebaseFirestore.instance.collection('razas');
                    if (_idEditando != null) {
                      await razas.doc(_idEditando).update(razaData);
                    } else {
                      await razas.add(razaData);
                    }
                    if (mounted) Navigator.of(context).pop();
                    _resetForm();
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _eliminarRaza(String id) async {
    await FirebaseFirestore.instance.collection('razas').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Razas'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('razas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final razas = snapshot.data?.docs ?? [];
          if (razas.isEmpty) {
            return const Center(child: Text('No hay razas registradas.'));
          }
          return ListView.builder(
            itemCount: razas.length,
            itemBuilder: (context, index) {
              final raza = razas[index];
              return ListTile(
                leading: raza['imagen'] != null
                    ? Image.network(raza['imagen'], width: 50)
                    : const Icon(Icons.image),
                title: Text(raza['nombre'] ?? ''),
                subtitle: Text('Ventajas: ${(raza['ventajas'] as List).length}, Desventajas: ${(raza['desventajas'] as List).length}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _mostrarFormulario(raza: raza),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _eliminarRaza(raza.id),
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
