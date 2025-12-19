import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminTropasScreen extends StatefulWidget {
  const AdminTropasScreen({super.key});

  @override
  State<AdminTropasScreen> createState() => _AdminTropasScreenState();
}

class _AdminTropasScreenState extends State<AdminTropasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _nivelController = TextEditingController();
  final _precioController = TextEditingController();
  final _tipoController = TextEditingController();
  final _bonoController = TextEditingController();
  final _vidaController = TextEditingController();
  final _ataqueController = TextEditingController();
  final _defensaController = TextEditingController();
  final _danioController = TextEditingController();
  final _velocidadController = TextEditingController();
  String? _razaSeleccionada;
  List<String> _razasDisponibles = [];

  Uint8List? _webImageBytes;
  io.File? _mobileImage;
  String? _imagenUrl;
  String? _idEditando;

  @override
  void initState() {
    super.initState();
    _cargarRazas();
  }

  Future<void> _cargarRazas() async {
    final snapshot = await FirebaseFirestore.instance.collection('razas').get();
    setState(() {
      _razasDisponibles = snapshot.docs.map((doc) => doc['nombre'].toString()).toList();
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nombreController.clear();
    _nivelController.clear();
    _precioController.clear();
    _tipoController.clear();
    _bonoController.clear();
    _vidaController.clear();
    _ataqueController.clear();
    _defensaController.clear();
    _danioController.clear();
    _velocidadController.clear();
    _razaSeleccionada = null;
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

  Future<void> _mostrarFormulario({DocumentSnapshot? tropa}) async {
    if (tropa != null) {
      final data = tropa.data() as Map<String, dynamic>;
      _idEditando = tropa.id;
      _nombreController.text = data['nombre'] ?? '';
      _nivelController.text = data['nivel'].toString();
      _precioController.text = data['precio'].toString();
      _tipoController.text = data['tipo'] ?? '';
      _bonoController.text = data['bono'] ?? '';
      _vidaController.text = data['vida'].toString();
      _ataqueController.text = data['ataque'].toString();
      _defensaController.text = data['defensa'].toString();
      _danioController.text = data['danio'].toString();
      _velocidadController.text = data['velocidad'].toString();
      _razaSeleccionada = data['raza'] ?? '';
      _imagenUrl = data['imagenUrl'];
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_idEditando == null ? 'Crear Tropa' : 'Editar Tropa'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre')),
                TextFormField(controller: _nivelController, decoration: const InputDecoration(labelText: 'Nivel'), keyboardType: TextInputType.number),
                TextFormField(controller: _precioController, decoration: const InputDecoration(labelText: 'Precio'), keyboardType: TextInputType.number),
                TextFormField(controller: _tipoController, decoration: const InputDecoration(labelText: 'Tipo')),
                TextFormField(controller: _bonoController, decoration: const InputDecoration(labelText: 'Bono')),
                TextFormField(controller: _vidaController, decoration: const InputDecoration(labelText: 'Vida'), keyboardType: TextInputType.number),
                TextFormField(controller: _ataqueController, decoration: const InputDecoration(labelText: 'Ataque'), keyboardType: TextInputType.number),
                TextFormField(controller: _defensaController, decoration: const InputDecoration(labelText: 'Defensa'), keyboardType: TextInputType.number),
                TextFormField(controller: _danioController, decoration: const InputDecoration(labelText: 'Daño'), keyboardType: TextInputType.number),
                TextFormField(controller: _velocidadController, decoration: const InputDecoration(labelText: 'Velocidad'), keyboardType: TextInputType.number),
                DropdownButtonFormField<String>(
                  value: _razaSeleccionada,
                  hint: const Text('Seleccionar raza'),
                  items: _razasDisponibles.map((raza) => DropdownMenuItem(value: raza, child: Text(raza))).toList(),
                  onChanged: (value) => setState(() => _razaSeleccionada = value),
                ),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: _seleccionarImagen, child: const Text('Seleccionar imagen')),
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
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate() || _razaSeleccionada == null) return;

              String? url = _imagenUrl;
              if (_webImageBytes != null || _mobileImage != null) {
                final nombreArchivo = '${DateTime.now().millisecondsSinceEpoch}_${_nombreController.text.trim()}';
                final ref = FirebaseStorage.instance.ref().child('tropas/$nombreArchivo.png');
                if (kIsWeb) {
                  await ref.putData(_webImageBytes!);
                } else {
                  await ref.putFile(_mobileImage!);
                }
                url = await ref.getDownloadURL();
              }

              final tropaData = {
                'nombre': _nombreController.text.trim(),
                'nivel': int.tryParse(_nivelController.text) ?? 0,
                'precio': int.tryParse(_precioController.text) ?? 0,
                'tipo': _tipoController.text.trim(),
                'bono': _bonoController.text.trim(),
                'vida': int.tryParse(_vidaController.text) ?? 0,
                'ataque': int.tryParse(_ataqueController.text) ?? 0,
                'defensa': int.tryParse(_defensaController.text) ?? 0,
                'danio': int.tryParse(_danioController.text) ?? 0,
                'velocidad': int.tryParse(_velocidadController.text) ?? 0,
                'raza': _razaSeleccionada,
                'imagenUrl': url,
              };

              final tropas = FirebaseFirestore.instance.collection('tropas');
              if (_idEditando != null) {
                await tropas.doc(_idEditando).update(tropaData);
              } else {
                await tropas.add(tropaData);
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

  Future<void> _eliminarTropa(String id) async {
    await FirebaseFirestore.instance.collection('tropas').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRUD de Tropas'), backgroundColor: Colors.orange),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tropas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tropas = snapshot.data?.docs ?? [];

          if (tropas.isEmpty) {
            return const Center(child: Text('No hay tropas registradas.'));
          }

          return ListView.builder(
            itemCount: tropas.length,
            itemBuilder: (context, index) {
              final tropa = tropas[index];
              return ListTile(
                leading: tropa['imagenUrl'] != null
                  ? Image.network(tropa['imagenUrl'], height: 40, width: 40, fit: BoxFit.cover)
                  : null,
                title: Text(tropa['nombre'] ?? ''),
                subtitle: Text('Nivel: ${tropa['nivel']} | Raza: ${tropa['raza']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _mostrarFormulario(tropa: tropa)),
                    IconButton(icon: const Icon(Icons.delete), onPressed: () => _eliminarTropa(tropa.id)),
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
