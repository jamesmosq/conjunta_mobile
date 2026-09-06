import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../porteria/models/visit.dart';
import '../../../porteria/providers/porteria_provider.dart';
import '../../models/parking_spot.dart';
import '../../providers/parking_provider.dart';

class ParkingScreen extends ConsumerStatefulWidget {
  const ParkingScreen({super.key});

  @override
  ConsumerState<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends ConsumerState<ParkingScreen> {
  // null = todos. QA #32: portero necesita confirmar de un vistazo cuántos
  // parqueaderos de VISITANTES quedan libres (antes solo había una lista
  // plana sin conteos ni forma de separar privados de visitantes).
  String? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final spotsAsync = ref.watch(parkingSpotsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Parqueaderos')),
      body: AsyncValueWidget<List<ParkingSpot>>(
        value: spotsAsync,
        data: (spots) {
          final filtered = _typeFilter == null
              ? spots
              : spots.where((s) => s.type == _typeFilter).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(parkingSpotsProvider.notifier).refresh(),
            child: Column(
              children: [
                _SummaryHeader(
                  spots: spots,
                  selected: _typeFilter,
                  onSelect: (type) => setState(() => _typeFilter = type),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text('No hay parqueaderos registrados',
                              style: TextStyle(color: Colors.grey.shade500)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _SpotCard(spot: filtered[i]),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.spots,
    required this.selected,
    required this.onSelect,
  });

  final List<ParkingSpot> spots;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final visitor = spots.where((s) => s.type == 'visitor').toList();
    final fixed = spots.where((s) => s.type == 'fixed').toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _CountChip(
              label: 'Visitantes',
              free: visitor.where((s) => s.isAvailable).length,
              total: visitor.length,
              selected: selected == 'visitor',
              onTap: () => onSelect(selected == 'visitor' ? null : 'visitor'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CountChip(
              label: 'Privados',
              free: fixed.where((s) => s.isAvailable).length,
              total: fixed.length,
              selected: selected == 'fixed',
              onTap: () => onSelect(selected == 'fixed' ? null : 'fixed'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.free,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int free;
  final int total;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$free/$total',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: selected ? cs.onPrimaryContainer : cs.onSurface,
              ),
            ),
            Text(
              '$label libres',
              style: TextStyle(
                fontSize: 11,
                color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
            ),
          ],
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
