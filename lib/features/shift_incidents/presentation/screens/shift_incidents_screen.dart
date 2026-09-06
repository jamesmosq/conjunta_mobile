import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/shift_incident_repository.dart';
import '../../models/shift_incident.dart';

final _shiftIncidentsProvider = FutureProvider.autoDispose
    .family<List<ShiftIncident>, String?>((ref, urgency) {
  return ref.read(shiftIncidentRepositoryProvider).getIncidents(
        urgency: urgency,
      );
});

/// Bandeja de novedades de turno — útil para el relevo entre porteros y
/// para que administración las consulte sin depender solo del aviso en
/// tiempo real de las urgentes (que se pierde si nadie estaba mirando la
/// pantalla en ese momento).
class ShiftIncidentsScreen extends ConsumerStatefulWidget {
  const ShiftIncidentsScreen({super.key});

  @override
  ConsumerState<ShiftIncidentsScreen> createState() =>
      _ShiftIncidentsScreenState();
}

class _ShiftIncidentsScreenState extends ConsumerState<ShiftIncidentsScreen> {
  String? _urgencyFilter;

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(_shiftIncidentsProvider(_urgencyFilter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novedades de turno'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<String?>(
              segments: const [
                ButtonSegment(value: null, label: Text('Todas')),
                ButtonSegment(value: 'normal', label: Text('Normal')),
                ButtonSegment(value: 'urgent', label: Text('Urgente')),
              ],
              selected: {_urgencyFilter},
              onSelectionChanged: (s) =>
                  setState(() => _urgencyFilter = s.first),
            ),
          ),
        ),
      ),
      body: incidentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                const Text('No se pudieron cargar las novedades.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(_shiftIncidentsProvider(_urgencyFilter)),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (incidents) {
          if (incidents.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined, size: 56, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay novedades registradas'),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(_shiftIncidentsProvider(_urgencyFilter)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: incidents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _IncidentCard(incident: incidents[i]),
            ),
          );
        },
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident});
  final ShiftIncident incident;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: incident.isUrgent ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    incident.categoryLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (incident.isUrgent) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber,
                            size: 11, color: Colors.red.shade700),
                        const SizedBox(width: 3),
                        Text(
                          'URGENTE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(incident.description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                if (incident.reportedBy != null) ...[
                  const Icon(Icons.person_outline,
                      size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    incident.reportedBy!,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(width: 10),
                ],
                const Icon(Icons.access_time, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _relativeTime(incident.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _relativeTime(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }
}
