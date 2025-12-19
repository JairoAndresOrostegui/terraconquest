import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PartidasScreen extends StatelessWidget {
  const PartidasScreen({super.key});

  String _formatearFecha(Timestamp ts) {
    final dt = ts.toDate();
    return DateFormat('dd/MM/yyyy – HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No estás autenticado')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('Partidas disponibles'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('partidas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay partidas disponibles', style: TextStyle(color: Colors.white70)),
            );
          }

          final partidas = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: partidas.length,
            itemBuilder: (context, index) {
              final data = partidas[index].data() as Map<String, dynamic>;
              final estado = data['estado'] ?? 'indefinido';

              return Card(
                color: estado == 'futura'
                    ? Colors.blueGrey[800]
                    : estado == 'activa'
                        ? Colors.green[900]
                        : Colors.grey[800],
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    data['nombre'] ?? 'Partida sin nombre',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Inicio: ${_formatearFecha(data['fechaInicio'])}\n'
                    'Fin: ${_formatearFecha(data['fechaFin'])}\n'
                    'Estado: $estado',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: estado == 'futura'
                      ? const Text('Abierta', style: TextStyle(color: Colors.amber))
                      : estado == 'activa'
                          ? ElevatedButton(
                              onPressed: () {
                                // Ir a elegir imperio/entrar
                              },
                              child: const Text('Entrar'),
                            )
                          : const Text('Finalizada', style: TextStyle(color: Colors.grey)),
                  onTap: () {
                    // Aquí luego irá el detalle o inscripción a la partida
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
