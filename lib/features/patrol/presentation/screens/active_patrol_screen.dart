import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/patrol_checkpoint.dart';
import '../../models/patrol_session.dart';
import '../../providers/patrol_provider.dart';

class ActivePatrolScreen extends ConsumerStatefulWidget {
  const ActivePatrolScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<ActivePatrolScreen> createState() => _ActivePatrolScreenState();
}

class _ActivePatrolScreenState extends ConsumerState<ActivePatrolScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existing = ref.read(patrolProvider).session;
      if (existing == null || existing.id != widget.sessionId) {
        ref.read(patrolProvider.notifier).loadSession(widget.sessionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patrolProvider);
    final session = state.session;

    if (state.isLoading && session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ronda activa')),
        body: Center(
          child: Text(state.error ?? 'Sesión no encontrada'),
        ),
      );
    }

    final route = session.route;
    final totalCheckpoints = route?.checkpoints.length ?? 0;
    final scanned = session.checkpointsScanned;
    final progress = totalCheckpoints > 0 ? scanned / totalCheckpoints : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(route?.name ?? 'Ronda activa'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Finalizar ronda',
            onPressed: () => _confirmFinish(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _ProgressHeader(
            scanned: scanned,
            total: totalCheckpoints,
            progress: progress,
            incidents: session.incidents.length,
          ),
          Expanded(
            child: route == null
                ? const Center(child: Text('Cargando ruta...'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: route.checkpoints.length,
                    itemBuilder: (_, i) {
                      final cp = route.checkpoints[i];
                      final done = session.scannedCheckpointIds.contains(cp.id);
                      return _CheckpointTile(
                        checkpoint: cp,
                        isDone: done,
                        sessionId: session.id,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/patrol/scan/${session.id}'),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear QR'),
        backgroundColor: Colors.indigo.shade700,
      ),
    );
  }

  Future<void> _confirmFinish(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Finalizar ronda?'),
        content: const Text(
          'Se calculará el porcentaje de cumplimiento y no podrás registrar más checkpoints.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final finished = await ref.read(patrolProvider.notifier).finishSession();
    if (!context.mounted) return;

    if (finished != null) {
      _showResultDialog(context, finished);
    } else {
      final error = ref.read(patrolProvider).error ?? 'Error al finalizar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  void _showResultDialog(BuildContext context, PatrolSession session) {
    final pct = session.compliancePct?.toStringAsFixed(1) ?? '0.0';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Ronda finalizada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              '$pct% cumplimiento',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${session.checkpointsScanned} checkpoints escaneados',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              ref.read(patrolProvider.notifier).clearSession();
              context.go('/porteria');
            },
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.scanned,
    required this.total,
    required this.progress,
    required this.incidents,
  });

  final int scanned;
  final int total;
  final double progress;
  final int incidents;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.indigo.shade700,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$scanned / $total checkpoints',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (incidents > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$incidents incidencia${incidents > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.indigo.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckpointTile extends StatelessWidget {
  const _CheckpointTile({
    required this.checkpoint,
    required this.isDone,
    required this.sessionId,
  });

  final PatrolCheckpoint checkpoint;
  final bool isDone;
  final int sessionId;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDone ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDone ? Colors.green : Colors.grey.shade200,
          child: isDone
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : Text(
                  '${checkpoint.sequence}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          checkpoint.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey : null,
          ),
        ),
        subtitle: checkpoint.description != null
            ? Text(
                checkpoint.description!,
                style: const TextStyle(fontSize: 12),
              )
            : null,
        trailing: isDone
            ? const Icon(Icons.verified, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.report_outlined, color: Colors.orange),
                tooltip: 'Reportar incidencia aquí',
                onPressed: () => context.push(
                  '/patrol/incident/$sessionId',
                  extra: checkpoint.id,
                ),
              ),
      ),
    );
  }
}
