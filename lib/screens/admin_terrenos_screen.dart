import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' as io;

class AdminTerrenosScreen extends StatefulWidget {
  const AdminTerrenosScreen({super.key});

  @override
  State<AdminTerrenosScreen> createState() => _AdminTerrenosScreenState();
}

class _AdminTerrenosScreenState extends State<AdminTerrenosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _bonoPoblacionController = TextEditingController();
  final _bonoDefensaController = TextEditingController();
  final _bonoMagiaController = TextEditingController();
  final _bonoProduccionController = TextEditingController();
  final _descripcionController = TextEditingController();
  Uint8List? _webImageBytes;
  io.File? _mobileImage;
  String? _imagenUrl;
  String? _idEditando;

  void _resetForm() {
    _formKey.currentState?.reset();
    _nombreController.clear();
    _bonoPoblacionController.clear();
    _bonoDefensaController.clear();
    _bonoMagiaController.clear();
    _bonoProduccionController.clear();
    _descripcionController.clear();
    _webImageBytes = null;
    _mobileImage = null;
    _imagenUrl = null;
    _idEditando = null;
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _webImageBytes = bytes);
      } else {
        setState(() => _mobileImage = io.File(picked.path));
      }
    }
  }

  Future<void> _mostrarFormulario({DocumentSnapshot? terreno}) async {
    if (terreno != null) {
      _idEditando = terreno.id;
      _nombreController.text = terreno['nombre'];
      _bonoPoblacionController.text = terreno['bonoPoblacion']?.toString() ?? '';
      _bonoDefensaController.text = terreno['bonoDefensa']?.toString() ?? '';
      _bonoMagiaController.text = terreno['bonoMagia']?.toString() ?? '';
      _bonoProduccionController.text = terreno['bonoProduccion']?.toString() ?? '';
      _descripcionController.text = terreno['descripcion'] ?? '';
      _imagenUrl = terreno['imagenUrl'];
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_idEditando == null ? 'Crear Terreno' : 'Editar Terreno'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _bonoPoblacionController,
                  decoration:
                      const InputDecoration(labelText: 'Bono Población'),
                ),
                TextFormField(
                  controller: _bonoDefensaController,
                  decoration:
                      const InputDecoration(labelText: 'Bono Defensa'),
                ),
                TextFormField(
                  controller: _bonoMagiaController,
                  decoration:
                      const InputDecoration(labelText: 'Bono Magia'),
                ),
                TextFormField(
                  controller: _bonoProduccionController,
                  decoration:
                      const InputDecoration(labelText: 'Bono Producción'),
                ),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _seleccionarImagen,
                  child: const Text('Seleccionar imagen'),
                ),
                const SizedBox(height: 10),
                if (_webImageBytes != null)
                  Image.memory(_webImageBytes!, height: 100)
                else if (_mobileImage != null)
                  Image.file(_mobileImage!, height: 100)
                else if (_imagenUrl != null)
                  Image.network(_imagenUrl!, height: 100),
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
              if (_webImageBytes != null || _mobileImage != null) {
                final nombreArchivo =
                    '${DateTime.now().millisecondsSinceEpoch}_${_nombreController.text.trim()}';
                final ref = FirebaseStorage.instance
                    .ref()
                    .child('terrenos/$nombreArchivo');

                if (kIsWeb) {
                  await ref.putData(_webImageBytes!);
                } else {
                  await ref.putFile(_mobileImage!);
                }

                url = await ref.getDownloadURL();
              }

              final terrenoData = {
                'nombre': _nombreController.text.trim(),
                'bonoPoblacion': _bonoPoblacionController.text.trim(),
                'bonoDefensa': _bonoDefensaController.text.trim(),
                'bonoMagia': _bonoMagiaController.text.trim(),
                'bonoProduccion': _bonoProduccionController.text.trim(),
                'descripcion': _descripcionController.text.trim(),
                'imagenUrl': url,
              };

              final terrenos =
                  FirebaseFirestore.instance.collection('terrenos');

              if (_idEditando != null) {
                await terrenos.doc(_idEditando).update(terrenoData);
              } else {
                await terrenos.add(terrenoData);
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

  Future<void> _eliminarTerreno(String id) async {
    await FirebaseFirestore.instance.collection('terrenos').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD de Terrenos'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('terrenos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final terrenos = snapshot.data?.docs ?? [];

          if (terrenos.isEmpty) {
            return const Center(child: Text('No hay terrenos registrados.'));
          }

          return ListView.builder(
            itemCount: terrenos.length,
            itemBuilder: (context, index) {
              final terreno = terrenos[index];
              return ListTile(
                leading: terreno['imagenUrl'] != null
                    ? Image.network(
                        terreno['imagenUrl'], height: 40, width: 40, fit: BoxFit.cover)
                    : null,
                title: Text(terreno['nombre'] ?? ''),
                subtitle: Text(terreno['descripcion'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _mostrarFormulario(terreno: terreno),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _eliminarTerreno(terreno.id),
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
