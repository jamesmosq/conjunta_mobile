import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../porteria/models/visit.dart';
import '../../../porteria/providers/porteria_provider.dart';
import '../../models/parking_spot.dart';
import '../../providers/parking_provider.dart';

class ParkingScreen extends ConsumerWidget {
  const ParkingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotsAsync = ref.watch(parkingSpotsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Parqueaderos')),
      body: AsyncValueWidget<List<ParkingSpot>>(
        value: spotsAsync,
        data: (spots) => RefreshIndicator(
          onRefresh: () => ref.read(parkingSpotsProvider.notifier).refresh(),
          child: spots.isEmpty
              ? Center(
                  child: Text('No hay parqueaderos registrados',
                      style: TextStyle(color: Colors.grey.shade500)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: spots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _SpotCard(spot: spots[i]),
                ),
        ),
      ),
    );
  }
}

class _SpotCard extends ConsumerWidget {
  const _SpotCard({required this.spot});
  final ParkingSpot spot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: spot.isAvailable
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.orange.withValues(alpha: 0.15),
          child: Icon(Icons.local_parking,
              color: spot.isAvailable ? Colors.green : Colors.orange),
        ),
        title: Text(spot.identifier,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(spot.typeLabel),
        trailing: spot.isAvailable
            ? FilledButton.tonal(
                onPressed: () => _showAssignSheet(context, ref),
                child: const Text('Asignar'),
              )
            : OutlinedButton(
                onPressed: () => _release(context, ref),
                child: const Text('Liberar'),
              ),
      ),
    );
  }

  Future<void> _release(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(parkingSpotsProvider.notifier).release(spot.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${spot.identifier} liberado.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo liberar el espacio.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAssignSheet(BuildContext context, WidgetRef ref) async {
    final visitsAsync = ref.read(visitsProvider);
    final visits =
        (visitsAsync.value ?? []).where((v) => v.isActive).toList();

    if (visits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay visitas activas para asignar.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<Visit>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Asignar ${spot.identifier} a...',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ...visits.map((v) => ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(v.visitorName),
                  onTap: () => Navigator.pop(ctx, v),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected == null || !context.mounted) return;

    try {
      await ref
          .read(parkingSpotsProvider.notifier)
          .assign(spot.id, selected.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${spot.identifier} asignado a ${selected.visitorName}.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo asignar el espacio.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
