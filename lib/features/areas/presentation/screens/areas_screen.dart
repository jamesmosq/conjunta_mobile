import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../models/booking.dart';
import '../../models/common_area.dart';
import '../../providers/areas_provider.dart';

class AreasScreen extends ConsumerWidget {
  const AreasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Áreas Comunes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reservar', icon: Icon(Icons.calendar_month_outlined)),
              Tab(text: 'Mis Reservas', icon: Icon(Icons.bookmark_outline)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AreasListTab(),
            _MyBookingsTab(),
          ],
        ),
      ),
    );
  }
}

// ── Areas list ────────────────────────────────────────────────────────────────

class _AreasListTab extends ConsumerWidget {
  const _AreasListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(commonAreasProvider);
    return AsyncValueWidget<List<CommonArea>>(
      value: areasAsync,
      data: (areas) => RefreshIndicator(
        onRefresh: () => ref.read(commonAreasProvider.notifier).refresh(),
        child: areas.isEmpty
            ? const Center(child: Text('No hay áreas comunes disponibles'))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: areas.length,
                itemBuilder: (_, i) => _AreaCard(area: areas[i]),
              ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area});
  final CommonArea area;

  static const _icons = {
    'piscina': Icons.pool_outlined,
    'salon': Icons.meeting_room_outlined,
    'salón': Icons.meeting_room_outlined,
    'bbq': Icons.outdoor_grill_outlined,
    'cancha': Icons.sports_soccer_outlined,
    'gym': Icons.fitness_center_outlined,
    'gimnasio': Icons.fitness_center_outlined,
    'parque': Icons.park_outlined,
  };

  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    for (final entry in _icons.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.location_on_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/areas/${area.id}', extra: area),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_iconFor(area.name), size: 48,
                  color: area.isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey),
              const SizedBox(height: 12),
              Text(area.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              if (area.capacity != null) ...[
                const SizedBox(height: 4),
                Text('Cap. ${area.capacity} personas',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              const SizedBox(height: 8),
              if (!area.isActive)
                const StatusChip(label: 'No disponible', color: Colors.grey)
              else
                FilledButton.tonal(
                  onPressed: () =>
                      context.push('/areas/${area.id}', extra: area),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12)),
                  child: const Text('Ver área'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── My Bookings ───────────────────────────────────────────────────────────────

class _MyBookingsTab extends ConsumerWidget {
  const _MyBookingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    return AsyncValueWidget<List<Booking>>(
      value: bookingsAsync,
      data: (bookings) => RefreshIndicator(
        onRefresh: () => ref.read(myBookingsProvider.notifier).refresh(),
        child: bookings.isEmpty
            ? const Center(child: Text('No tienes reservas'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
              ),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yyyy', 'es');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(booking.commonAreaName ?? 'Área #${booking.commonAreaId}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                StatusChip.forBookingStatus(booking.status),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.calendar_today_outlined,
                fmt.format(DateTime.parse(booking.date))),
            const SizedBox(height: 4),
            _infoRow(Icons.access_time_outlined,
                '${booking.startTime} – ${booking.endTime}'),
            if (booking.canCancel) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red)),
                  onPressed: () => _confirmCancel(context, ref),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      );

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(myBookingsProvider.notifier)
          .cancel(booking.id, reasonCtrl.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada')),
        );
      }
    }
  }
}
