import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../services/admin_partida_service.dart';

class AdminPartidasToolsScreen extends StatefulWidget {
  const AdminPartidasToolsScreen({
    super.key,
    required this.partidaId,
  });

  final String partidaId;

  @override
  State<AdminPartidasToolsScreen> createState() =>
      _AdminPartidasToolsScreenState();
}

class _AdminPartidasToolsScreenState extends State<AdminPartidasToolsScreen> {
  final AdminPartidaService _service = AdminPartidaService();

  bool _procesando = false;
  bool _desbloqueando = false;
  bool _creandoSeed = false;

  Future<void> _pasarDia() async {
    if (_procesando) return;

    setState(() => _procesando = true);

    try {
      final result = await _service.pasarDiaPartida(
        partidaId: widget.partidaId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Día ${result['diaProcesado']} procesado. Imperios: ${result['imperiosProcesados']}, ciudades: ${result['ciudadesProcesadas']}.',
          ),
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'No se pudo ejecutar el paso de día.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo ejecutar el paso de día.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Future<void> _seedDatosIniciales() async {
    if (_creandoSeed || _procesando || _desbloqueando) return;

    setState(() => _creandoSeed = true);

    try {
      final result = await _service.seedDatosIniciales();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['mensaje']?.toString() ?? 'Datos iniciales creados.'),
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'No se pudieron crear los datos iniciales.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron crear los datos iniciales.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _creandoSeed = false);
      }
    }
  }

  Future<void> _desbloquearPasoDia() async {
    if (_desbloqueando || _procesando) return;

    setState(() => _desbloqueando = true);

    try {
      final result = await _service.desbloquearPasoDia(
        partidaId: widget.partidaId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['mensaje']?.toString() ?? 'Paso de día desbloqueado.'),
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'No se pudo desbloquear el paso de día.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo desbloquear el paso de día.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _desbloqueando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Herramientas de partida'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Semantics(
                button: true,
                enabled: !_procesando && !_desbloqueando && !_creandoSeed,
                focusable: true,
                label: 'Ejecutar paso de día manual',
                child: FilledButton.icon(
                  onPressed: _procesando || _desbloqueando || _creandoSeed
                      ? null
                      : _pasarDia,
                  icon: _procesando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calendar_month),
                  label: Text(_procesando ? 'Procesando...' : 'Pasar día'),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                enabled: !_desbloqueando && !_procesando && !_creandoSeed,
                focusable: true,
                label: 'Desbloquear paso de día',
                child: OutlinedButton.icon(
                  onPressed: _desbloqueando || _procesando || _creandoSeed
                      ? null
                      : _desbloquearPasoDia,
                  icon: _desbloqueando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open),
                  label: Text(
                    _desbloqueando
                        ? 'Desbloqueando...'
                        : 'Desbloquear paso de día',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                enabled: !_creandoSeed && !_procesando && !_desbloqueando,
                focusable: true,
                label: 'Crear datos iniciales de prueba',
                child: OutlinedButton.icon(
                  onPressed: _creandoSeed || _procesando || _desbloqueando
                      ? null
                      : _seedDatosIniciales,
                  icon: _creandoSeed
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.storage),
                  label: Text(
                    _creandoSeed ? 'Creando datos...' : 'Crear datos iniciales',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
