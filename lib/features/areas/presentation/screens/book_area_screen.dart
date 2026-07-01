import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../data/areas_repository.dart';
import '../../providers/areas_provider.dart';

class BookAreaScreen extends ConsumerStatefulWidget {
  const BookAreaScreen({super.key, required this.areaId});
  final int areaId;

  @override
  ConsumerState<BookAreaScreen> createState() => _BookAreaScreenState();
}

class _BookAreaScreenState extends ConsumerState<BookAreaScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  bool _loading = false;

  final _dateFmt = DateFormat('dd/MM/yyyy', 'es');

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora de fin debe ser posterior al inicio')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(areasRepositoryProvider).createBooking(widget.areaId, {
        'date': _date.toIso8601String().substring(0, 10),
        'start_time': _formatTime(_startTime),
        'end_time': _formatTime(_endTime),
      });
      await ref.read(myBookingsProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva solicitada exitosamente')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final areaAsync = ref.watch(selectedAreaProvider(widget.areaId));
    return Scaffold(
      appBar: AppBar(
        title: AsyncValueWidget<dynamic>(
          value: areaAsync,
          data: (area) => Text('Reservar ${area.name}'),
          loading: const Text('Reservar área'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AsyncValueWidget<dynamic>(
              value: areaAsync,
              data: (area) => _AreaInfoCard(area: area),
            ),
            const SizedBox(height: 24),
            const Text('Fecha y horario',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Fecha'),
              subtitle: Text(_dateFmt.format(_date)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3))),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time_outlined),
                    title: const Text('Inicio'),
                    subtitle: Text(_formatTime(_startTime)),
                    onTap: () => _pickTime(isStart: true),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.3))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time_filled_outlined),
                    title: const Text('Fin'),
                    subtitle: Text(_formatTime(_endTime)),
                    onTap: () => _pickTime(isStart: false),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.3))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.bookmark_add_outlined),
              label: const Text('Solicitar Reserva'),
            ),
            const SizedBox(height: 8),
            const Text(
              'La reserva debe ser aprobada por la administración.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaInfoCard extends StatelessWidget {
  const _AreaInfoCard({required this.area});
  final dynamic area;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(area.name as String? ?? '',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            if (area.description != null) ...[
              const SizedBox(height: 8),
              Text(area.description as String,
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (area.capacity != null) ...[
                  const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${area.capacity} personas',
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 16),
                ],
                if (area.openTime != null) ...[
                  const Icon(Icons.access_time_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${area.openTime} – ${area.closeTime}',
                      style: const TextStyle(fontSize: 13)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
