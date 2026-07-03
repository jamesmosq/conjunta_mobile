import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../providers/patrol_provider.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear checkpoint'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: _controller.toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay with scan frame
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Apunta al código QR del checkpoint',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          if (_processing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;

    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null) return;

    Map<String, dynamic> payload;
    try {
      payload = json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      _showError('QR inválido — no es un checkpoint de ronda.');
      return;
    }

    if (payload['type'] != 'patrol_checkpoint') {
      _showError('Este QR no corresponde a un checkpoint de ronda.');
      return;
    }

    final uuid = payload['uuid'] as String?;
    final token = payload['token'] as String?;

    if (uuid == null || token == null) {
      _showError('QR incompleto — datos faltantes.');
      return;
    }

    setState(() => _processing = true);
    await _controller.stop();

    // Find checkpoint id from session route
    final session = ref.read(patrolProvider).session;
    final checkpointId = session?.route?.checkpoints
        .where((cp) => cp.uuid == uuid)
        .map((cp) => cp.id)
        .firstOrNull;

    final ok = await ref.read(patrolProvider.notifier).scanCheckpoint(
          uuid: uuid,
          token: token,
          checkpointId: checkpointId,
        );

    if (!mounted) return;
    setState(() => _processing = false);

    if (ok) {
      _showSuccess(checkpointId);
    } else {
      final error = ref.read(patrolProvider).error ?? 'Error al registrar checkpoint';
      _showError(error);
      await _controller.start();
    }
  }

  void _showSuccess(int? checkpointId) {
    final session = ref.read(patrolProvider).session;
    final cp = session?.route?.checkpoints
        .where((c) => c.id == checkpointId)
        .firstOrNull;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('¡Checkpoint registrado!'),
          ],
        ),
        content: Text(cp?.name ?? 'Checkpoint escaneado correctamente.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop(); // back to active patrol
            },
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _controller.start();
            },
            child: const Text('Escanear otro'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
