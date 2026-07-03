import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/patrol_route.dart';
import '../../providers/patrol_provider.dart';

class PatrolScreen extends ConsumerWidget {
  const PatrolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(patrolRoutesProvider);
    final state = ref.watch(patrolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rondas de Vigilancia'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(patrolRoutesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (routes) {
          if (routes.isEmpty) {
            return const Center(
              child: Text('No hay rutas de ronda configuradas.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _RouteCard(
              route: routes[i],
              isStarting: state.isLoading,
              onStart: () => _startSession(context, ref, routes[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _startSession(
    BuildContext context,
    WidgetRef ref,
    PatrolRoute route,
  ) async {
    final ok = await ref.read(patrolProvider.notifier).startSession(route.id);
    if (!context.mounted) return;

    if (ok) {
      final session = ref.read(patrolProvider).session;
      if (session != null) {
        context.push('/patrol/active/${session.id}');
      }
    } else {
      final error = ref.read(patrolProvider).error ?? 'Error al iniciar ronda';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.isStarting,
    required this.onStart,
  });

  final PatrolRoute route;
  final bool isStarting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            if (route.description != null) ...[
              const SizedBox(height: 6),
              Text(
                route.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.location_on,
                  label: '${route.checkpoints.length} puntos',
                ),
                if (route.estimatedMinutes != null) ...[
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.timer,
                    label: '~${route.estimatedMinutes} min',
                  ),
                ],
                const Spacer(),
                FilledButton.icon(
                  onPressed: isStarting ? null : onStart,
                  icon: isStarting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('Iniciar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.indigo.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.indigo.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
