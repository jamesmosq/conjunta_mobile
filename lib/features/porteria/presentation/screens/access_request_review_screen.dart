import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/porteria_repository.dart';
import '../../models/access_request.dart';

/// QA #10: pantalla que abre el copropietario al tocar el push (o desde la
/// bandeja de notificaciones) para aprobar/rechazar el ingreso de un
/// visitante que el portero está reteniendo en la entrada.
class AccessRequestReviewScreen extends ConsumerStatefulWidget {
  const AccessRequestReviewScreen({super.key, required this.accessRequestId});

  final int accessRequestId;

  @override
  ConsumerState<AccessRequestReviewScreen> createState() =>
      _AccessRequestReviewScreenState();
}

class _AccessRequestReviewScreenState
    extends ConsumerState<AccessRequestReviewScreen> {
  late Future<AccessRequest> _future;
  bool _responding = false;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(porteriaRepositoryProvider)
        .getAccessRequest(widget.accessRequestId);
  }

  Future<void> _respond(bool approved) async {
    // Guarda síncrona: un doble-tap muy rápido puede disparar dos onPressed
    // antes de que el rebuild deshabilite el botón (el closure del build
    // anterior sigue "vivo" hasta que Flutter repinta), así que _responding
    // debe revisarse aquí también, no solo en el onPressed del widget.
    if (_responding) return;
    setState(() => _responding = true);
    try {
      final updated = await ref
          .read(porteriaRepositoryProvider)
          .respondAccessRequest(widget.accessRequestId, approved);
      setState(() => _future = Future.value(updated));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar tu respuesta.')),
        );
      }
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Visitante en portería')),
      body: FutureBuilder<AccessRequest>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('No se pudo cargar la solicitud.'),
            );
          }

          final req = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.person_pin_circle_outlined, size: 72, color: cs.primary),
                const SizedBox(height: 16),
                Text(req.visitorName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                if (req.documentNumber != null) ...[
                  const SizedBox(height: 4),
                  Text('Documento: ${req.documentNumber}',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
                if (req.reason != null) ...[
                  const SizedBox(height: 8),
                  Text(req.reason!, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant)),
                ],
                const SizedBox(height: 32),
                if (req.isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _responding ? null : () => _respond(false),
                          icon: const Icon(Icons.close),
                          label: const Text('Rechazar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.error,
                            side: BorderSide(color: cs.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _responding ? null : () => _respond(true),
                          icon: const Icon(Icons.check),
                          label: const Text('Aprobar'),
                        ),
                      ),
                    ],
                  ),
                  if (_responding) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ] else
                  Column(
                    children: [
                      Chip(
                        label: Text(req.statusLabel),
                        backgroundColor: req.status == 'approved'
                            ? Colors.green.withValues(alpha: 0.15)
                            : cs.errorContainer,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => context.pop(),
                        child: const Text('Listo'),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
