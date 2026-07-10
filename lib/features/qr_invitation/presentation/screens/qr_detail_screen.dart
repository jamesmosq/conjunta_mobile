import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/visit_qr_code.dart';
import '../../providers/qr_invitation_provider.dart';
import '../widgets/status_badge.dart';

class QrDetailScreen extends ConsumerWidget {
  const QrDetailScreen({super.key, required this.qr});

  final VisitQrCode qr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for state changes (e.g. revoke updates status)
    final state = ref.watch(qrInvitationProvider);
    final current = state.qrCodes.where((q) => q.id == qr.id).firstOrNull ?? qr;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitación QR'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartir',
            onPressed: () => _share(context, current),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StatusBadge(estado: current.estado, large: true),
            const SizedBox(height: 20),

            // QR Code
            _QrWidget(qrUrl: current.qrUrl),
            const SizedBox(height: 8),
            Text(
              'Muestra este código al portero',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500),
            ),
            if (current.codigo != null && current.codigo!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'o dicta este código en portería',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Text(
                  current.codigo!,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Visitor info card
            _InfoCard(
              title: 'Visitante',
              rows: [
                ('Nombre', current.visitante.nombre),
                ('Documento',
                    '${current.visitante.tipoDocumentoLabel}: ${current.visitante.documento}'),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Vigencia',
              rows: [
                ('Desde', _formatDate(current.validoDesde)),
                ('Hasta', _formatDate(current.validoHasta)),
                if (current.usadoEn != null)
                  ('Usado el', _formatDate(current.usadoEn!)),
                if (current.revocadoEn != null)
                  ('Revocado el', _formatDate(current.revocadoEn!)),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            if (current.canRevoke)
              _RevokeButton(
                isLoading: state.isLoading,
                onRevoke: () => _confirmRevoke(context, ref, current.id),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context, VisitQrCode current) async {
    final fmt = DateFormat('dd/MM/yyyy', 'es');

    String fromStr = '';
    String untilStr = '';
    try {
      fromStr = fmt.format(DateTime.parse(current.validoDesde));
      untilStr = fmt.format(DateTime.parse(current.validoHasta));
    } catch (_) {}

    final text = '''
🏠 Invitación de visita — Conjunto Residencial

👤 Visitante: ${current.visitante.nombre}
📋 ${current.visitante.tipoDocumentoLabel}: ${current.visitante.documento}
📅 Válida: $fromStr – $untilStr

El portero debe escanear el QR en la app de portería.

🔗 ${current.qrUrl}
''';

    await Share.share(text, subject: 'Invitación QR de visita');
  }

  Future<void> _confirmRevoke(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Revocar invitación?'),
        content: const Text(
          'El QR dejará de ser válido inmediatamente. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final ok = await ref.read(qrInvitationProvider.notifier).revoke(id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Invitación revocada correctamente.'
            : (ref.read(qrInvitationProvider).error ?? 'Error al revocar.')),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy', 'es')
          .format(DateTime.parse(dateStr).toLocal());
    } catch (_) {
      return dateStr;
    }
  }
}

// ── QR Widget ─────────────────────────────────────────────────────────────────

class _QrWidget extends StatefulWidget {
  const _QrWidget({required this.qrUrl});

  final String qrUrl;

  @override
  State<_QrWidget> createState() => _QrWidgetState();
}

class _QrWidgetState extends State<_QrWidget> {
  final GlobalKey _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: QrImageView(
          data: widget.qrUrl,
          version: QrVersions.auto,
          size: 220,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Colors.deepPurple.shade800,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.deepPurple.shade800,
          ),
          errorStateBuilder: (_, __) =>
              const Icon(Icons.error, color: Colors.red),
        ),
      ),
    );
  }

  Future<Uint8List?> captureQrImage() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.deepPurple.shade600,
                letterSpacing: 0.5,
              ),
            ),
            const Divider(height: 16),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        r.$1,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.$2,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Revoke button ─────────────────────────────────────────────────────────────

class _RevokeButton extends StatelessWidget {
  const _RevokeButton({required this.isLoading, required this.onRevoke});

  final bool isLoading;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onRevoke,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.block, color: Colors.red),
        label: const Text(
          'Revocar invitación',
          style: TextStyle(color: Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
