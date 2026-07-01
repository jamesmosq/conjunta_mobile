import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../models/booking.dart';
import '../../models/common_area.dart';
import '../../providers/areas_provider.dart';

class AreaDetailScreen extends ConsumerStatefulWidget {
  const AreaDetailScreen({super.key, required this.areaId, this.area});

  final int areaId;
  // Passed via extra to avoid extra network round-trip when coming from catalog.
  final CommonArea? area;

  @override
  ConsumerState<AreaDetailScreen> createState() => _AreaDetailScreenState();
}

class _AreaDetailScreenState extends ConsumerState<AreaDetailScreen> {
  late DateTime _selectedDate;
  final _dateFmt = DateFormat('dd/MM/yyyy', 'es');
  final _dateFmtKey = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    // Default to tomorrow so the availability picker is meaningful.
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day + 1);
  }

  Future<void> _pickDate(CommonArea area) async {
    final advanceDays = area.advanceDays ?? 1;
    final firstDate =
        DateTime.now().add(Duration(days: advanceDays.clamp(1, 30)));
    final lastDate = DateTime.now().add(const Duration(days: 90));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(firstDate) ? _selectedDate : firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final areaAsync = widget.area != null
        ? AsyncValue.data(widget.area!)
        : ref.watch(selectedAreaProvider(widget.areaId));

    return Scaffold(
      body: AsyncValueWidget<CommonArea>(
        value: areaAsync,
        data: (area) => _DetailBody(
          area: area,
          selectedDate: _selectedDate,
          dateFmt: _dateFmt,
          dateFmtKey: _dateFmtKey,
          onPickDate: () => _pickDate(area),
        ),
      ),
      floatingActionButton: areaAsync.valueOrNull?.isActive == true
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/areas/${widget.areaId}/book'),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Reservar'),
            )
          : null,
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.area,
    required this.selectedDate,
    required this.dateFmt,
    required this.dateFmtKey,
    required this.onPickDate,
  });

  final CommonArea area;
  final DateTime selectedDate;
  final DateFormat dateFmt;
  final DateFormat dateFmtKey;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateKey = dateFmtKey.format(selectedDate);
    final availAsync =
        ref.watch(areaAvailabilityProvider((areaId: area.id, date: dateKey)));

    final cs = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              area.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primaryContainer,
                    cs.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  _iconFor(area.name),
                  size: 96,
                  color: cs.onPrimaryContainer.withAlpha(180),
                ),
              ),
            ),
          ),
          actions: [
            if (!area.isActive)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  label: const Text('No disponible'),
                  backgroundColor: cs.errorContainer,
                  labelStyle: TextStyle(
                      color: cs.onErrorContainer, fontSize: 12),
                ),
              ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info chips ────────────────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (area.capacity != null)
                      _InfoChip(
                        icon: Icons.people_outline,
                        label: '${area.capacity} personas',
                      ),
                    if (area.openTime != null)
                      _InfoChip(
                        icon: Icons.access_time_outlined,
                        label: '${area.openTime} – ${area.closeTime}',
                      ),
                    if (area.advanceDays != null)
                      _InfoChip(
                        icon: Icons.event_outlined,
                        label: 'Reservar con ${area.advanceDays} días de anticipación',
                      ),
                    if (area.feePerHour != null)
                      _InfoChip(
                        icon: Icons.payments_outlined,
                        label: '\$${_fmt(area.feePerHour!)}/hora',
                        color: cs.tertiaryContainer,
                        textColor: cs.onTertiaryContainer,
                      ),
                  ],
                ),

                // ── Description ───────────────────────────────────────────
                if (area.description != null) ...[
                  const SizedBox(height: 20),
                  Text('Descripción',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    area.description!,
                    style: TextStyle(
                        height: 1.5, color: cs.onSurfaceVariant),
                  ),
                ],

                // ── Rules ─────────────────────────────────────────────────
                if (area.rules != null) ...[
                  const SizedBox(height: 20),
                  Text('Reglamento',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      area.rules!,
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: cs.onSurfaceVariant),
                    ),
                  ),
                ],

                // ── Availability section ───────────────────────────────────
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text('Disponibilidad',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onPickDate,
                      icon: const Icon(Icons.calendar_month_outlined, size: 16),
                      label: Text(
                        dateFmt.format(selectedDate),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _AvailabilitySection(asyncValue: availAsync),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(double v) {
    final n = NumberFormat('#,##0', 'es_CO');
    return n.format(v.toInt());
  }

  static const _iconMap = {
    'piscina': Icons.pool_outlined,
    'salon': Icons.meeting_room_outlined,
    'salón': Icons.meeting_room_outlined,
    'bbq': Icons.outdoor_grill_outlined,
    'cancha': Icons.sports_soccer_outlined,
    'gym': Icons.fitness_center_outlined,
    'gimnasio': Icons.fitness_center_outlined,
    'parque': Icons.park_outlined,
    'terraza': Icons.roofing_outlined,
    'auditorio': Icons.theater_comedy_outlined,
  };

  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    for (final entry in _iconMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.location_on_outlined;
  }
}

// ─── Availability section ─────────────────────────────────────────────────────

class _AvailabilitySection extends StatelessWidget {
  const _AvailabilitySection({required this.asyncValue});

  final AsyncValue<List<Booking>> asyncValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return asyncValue.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: cs.onErrorContainer, size: 16),
            const SizedBox(width: 8),
            Text('No se pudo cargar la disponibilidad',
                style: TextStyle(
                    color: cs.onErrorContainer, fontSize: 13)),
          ],
        ),
      ),
      data: (bookings) {
        if (bookings.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withAlpha(20),
              border: Border.all(
                  color: Colors.green.withAlpha(60)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Disponible todo el día',
                  style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horarios ya reservados:',
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bookings
                  .map((b) => _OccupiedSlot(booking: b))
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _OccupiedSlot extends StatelessWidget {
  const _OccupiedSlot({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block_outlined, size: 12, color: cs.onErrorContainer),
          const SizedBox(width: 4),
          Text(
            '${booking.startTime} – ${booking.endTime}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
    this.textColor,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = color ?? cs.surfaceContainerHighest;
    final fg = textColor ?? cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: fg)),
        ],
      ),
    );
  }
}
