import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../models/staff_badge.dart';
import '../../providers/staff_badge_provider.dart';

class MyBadgeScreen extends ConsumerWidget {
  const MyBadgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeAsync = ref.watch(myBadgeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi código de acceso'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: AsyncValueWidget<StaffBadge>(
        value: badgeAsync,
        data: (badge) => RefreshIndicator(
          onRefresh: () => ref.read(myBadgeProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _StatusChip(isInside: badge.isInside),
                const SizedBox(height: 20),
                Container(
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
                    data: badge.code,
                    version: QrVersions.auto,
                    size: 220,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.indigo.shade800,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Muéstralo en portería para registrar tu entrada o salida',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(badge.userName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(badge.roleLabel,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmRegenerate(context, ref),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerar código'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Si crees que alguien más pudo ver tu código, regénéralo — el anterior deja de funcionar de inmediato.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRegenerate(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Regenerar código?'),
        content: const Text(
          'El código actual dejará de funcionar de inmediato. Tendrás que mostrar el nuevo QR la próxima vez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Regenerar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(myBadgeProvider.notifier).regenerate();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código regenerado.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e, 'No se pudo regenerar el código.'))),
        );
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isInside});

  final bool isInside;

  @override
  Widget build(BuildContext context) {
    final MaterialColor color = isInside ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isInside ? Icons.login : Icons.logout, size: 15, color: color.shade700),
          const SizedBox(width: 6),
          Text(
            isInside ? 'Actualmente dentro del conjunto' : 'Actualmente fuera',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color.shade700),
          ),
        ],
      ),
    );
  }
}
