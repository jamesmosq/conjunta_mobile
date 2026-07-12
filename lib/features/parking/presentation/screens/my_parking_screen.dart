import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../models/parking_spot.dart';
import '../../providers/my_parking_provider.dart';

String _parkingErrorMessage(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
  }
  return fallback;
}

class MyParkingScreen extends ConsumerWidget {
  const MyParkingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(myParkingProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mi parqueadero')),
      body: AsyncValueWidget<MyParkingState>(
        value: stateAsync,
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.read(myParkingProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Mi parqueadero',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (state.mySpots.isEmpty)
                _emptyHint('No tienes un parqueadero fijo asignado')
              else
                ...state.mySpots.map((s) => _MySpotCard(spot: s)),
              const SizedBox(height: 24),
              Text('Disponibles para reclamar',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (state.availableToClaim.isEmpty)
                _emptyHint('No hay espacios libres en este momento')
              else
                ...state.availableToClaim.map((s) => _ClaimableSpotCard(spot: s)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text, style: TextStyle(color: Colors.grey.shade500)),
      );
}

class _MySpotCard extends ConsumerWidget {
  const _MySpotCard({required this.spot});
  final ParkingSpot spot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: spot.isAvailable
              ? Colors.orange.withValues(alpha: 0.15)
              : Colors.green.withValues(alpha: 0.15),
          child: Icon(Icons.local_parking,
              color: spot.isAvailable ? Colors.orange : Colors.green),
        ),
        title: Text(spot.identifier,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(spot.isAvailable ? 'Vacío' : 'Ocupado'),
        trailing: spot.isAvailable
            ? FilledButton.tonal(
                onPressed: () => _occupy(context, ref),
                child: const Text('Ya volví'),
              )
            : OutlinedButton(
                onPressed: () => _showVacateDialog(context, ref),
                child: const Text('Marqué que salí'),
              ),
      ),
    );
  }

  Future<void> _occupy(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(myParkingProvider.notifier).occupy(spot.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar el espacio.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showVacateDialog(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Qué pasó con tu espacio?'),
        content: const Text(
            'Esto libera el espacio para que otro residente pueda usarlo mientras tanto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'no_vehicle'),
            child: const Text('No tengo vehículo'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'vehicle_out'),
            child: const Text('Mi vehículo salió'),
          ),
        ],
      ),
    );

    if (reason == null || !context.mounted) return;

    try {
      await ref.read(myParkingProvider.notifier).vacate(spot.id, reason);
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
}

class _ClaimableSpotCard extends ConsumerWidget {
  const _ClaimableSpotCard({required this.spot});
  final ParkingSpot spot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.15),
          child: const Icon(Icons.local_parking, color: Colors.blue),
        ),
        title: Text(spot.identifier,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(spot.typeLabel),
        trailing: FilledButton(
          onPressed: () async {
            try {
              await ref.read(myParkingProvider.notifier).claim(spot.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${spot.identifier} reclamado.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_parkingErrorMessage(
                        e, 'No se pudo reclamar el espacio.')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Reclamar'),
        ),
      ),
    );
  }
}
