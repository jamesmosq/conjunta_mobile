import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/visit.dart';
import '../../providers/porteria_provider.dart';

class VisitHistoryScreen extends ConsumerWidget {
  const VisitHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visitHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de visitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Actualizar',
            onPressed: () => ref.read(visitHistoryProvider.notifier).refresh(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _MonthFilter(selectedMonth: state.month),
        ),
      ),
      body: _Body(state: state),
    );
  }
}

// ─── Month filter bar ─────────────────────────────────────────────────────────

class _MonthFilter extends ConsumerWidget {
  const _MonthFilter({required this.selectedMonth});

  final DateTime? selectedMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - i, 1);
      return m;
    });
    final fmt = DateFormat('MMM yyyy', 'es');

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: months.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            final selected = selectedMonth == null;
            return _FilterChip(
              label: 'Todo',
              selected: selected,
              onTap: () =>
                  ref.read(visitHistoryProvider.notifier).filterByMonth(null),
            );
          }
          final m = months[i - 1];
          final selected = selectedMonth != null &&
              selectedMonth!.year == m.year &&
              selectedMonth!.month == m.month;
          return _FilterChip(
            label: _capitalize(fmt.format(m)),
            selected: selected,
            onTap: () =>
                ref.read(visitHistoryProvider.notifier).filterByMonth(m),
          );
        },
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final VisitHistoryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.visits.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.visits.isEmpty && state.error != null) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref.read(visitHistoryProvider.notifier).loadMore(),
      );
    }

    if (state.visits.isEmpty) {
      return const _EmptyState();
    }

    final groups = _groupByDate(state.visits);
    final keys = groups.keys.toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(visitHistoryProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: keys.length + 1,
        itemBuilder: (context, i) {
          if (i == keys.length) {
            return _LoadMoreFooter(
              isLoading: state.isLoading,
              hasMore: state.hasMore,
              error: state.error,
              onLoadMore: () =>
                  ref.read(visitHistoryProvider.notifier).loadMore(),
            );
          }
          final dateKey = keys[i];
          final dayVisits = groups[dateKey]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateHeader(date: dateKey),
              ...dayVisits.map((v) => _VisitCard(visit: v)),
              const SizedBox(height: 4),
            ],
          );
        },
      ),
    );
  }

  /// Groups visits by yyyy-MM-dd key, preserving server-sorted order.
  Map<String, List<Visit>> _groupByDate(List<Visit> visits) {
    final result = <String, List<Visit>>{};
    for (final v in visits) {
      final dateStr = v.entryAt;
      String key;
      if (dateStr == null) {
        key = 'unknown';
      } else {
        try {
          final dt = DateTime.parse(dateStr).toLocal();
          key =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        } catch (_) {
          key = 'unknown';
        }
      }
      (result[key] ??= []).add(v);
    }
    return result;
  }
}

// ─── Date header ──────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = _label(date);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: cs.outlineVariant, height: 1)),
        ],
      ),
    );
  }

  String _label(String key) {
    if (key == 'unknown') return 'Sin fecha';
    try {
      final dt = DateTime.parse(key);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final d = DateTime(dt.year, dt.month, dt.day);
      if (d == today) return 'Hoy';
      if (d == yesterday) return 'Ayer';
      return DateFormat('EEEE d \'de\' MMMM', 'es').format(dt);
    } catch (_) {
      return key;
    }
  }
}

// ─── Visit card ───────────────────────────────────────────────────────────────

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeFmt = DateFormat('HH:mm', 'es');
    final departed = visit.exitAt != null;

    String? entryStr;
    String? exitStr;
    String? durationStr;

    if (visit.entryAt != null) {
      try {
        final entryDt = DateTime.parse(visit.entryAt!).toLocal();
        entryStr = timeFmt.format(entryDt);
        if (visit.exitAt != null) {
          final exitDt = DateTime.parse(visit.exitAt!).toLocal();
          exitStr = timeFmt.format(exitDt);
          final diff = exitDt.difference(entryDt);
          if (diff.inHours >= 1) {
            durationStr =
                '${diff.inHours}h ${diff.inMinutes.remainder(60)}min';
          } else {
            durationStr = '${diff.inMinutes}min';
          }
        }
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: departed
                  ? cs.surfaceContainerHighest
                  : cs.primaryContainer,
              child: Icon(
                departed
                    ? Icons.person_outline
                    : Icons.person,
                color: departed ? cs.onSurfaceVariant : cs.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          visit.visitorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusPill(departed: departed),
                    ],
                  ),
                  if (visit.document != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${visit.documentType ?? "Doc"}: ${visit.document}',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _TimeChip(
                        icon: Icons.login_outlined,
                        label: entryStr ?? '--:--',
                        color: Colors.green,
                      ),
                      if (exitStr != null) ...[
                        const SizedBox(width: 8),
                        _TimeChip(
                          icon: Icons.logout_outlined,
                          label: exitStr,
                          color: Colors.grey,
                        ),
                        if (durationStr != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.timer_outlined,
                              size: 12, color: cs.outlineVariant),
                          const SizedBox(width: 2),
                          Text(
                            durationStr,
                            style: TextStyle(
                                fontSize: 11, color: cs.outlineVariant),
                          ),
                        ],
                      ],
                    ],
                  ),
                  if (visit.registeredByName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Portería: ${visit.registeredByName}',
                      style: TextStyle(
                          fontSize: 11, color: cs.outlineVariant),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.departed});

  final bool departed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: departed
            ? Colors.grey.withAlpha(25)
            : Colors.green.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: departed
              ? Colors.grey.withAlpha(80)
              : Colors.green.withAlpha(80),
        ),
      ),
      child: Text(
        departed ? 'Salió' : 'Adentro',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: departed ? Colors.grey : Colors.green,
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── Load more footer ─────────────────────────────────────────────────────────

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
    this.error,
  });

  final bool isLoading;
  final bool hasMore;
  final String? error;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(error!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13)),
            const SizedBox(height: 8),
            TextButton(
                onPressed: onLoadMore, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No hay más visitas',
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: OutlinedButton(
          onPressed: onLoadMore,
          child: const Text('Cargar más'),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_outlined, size: 72, color: cs.outlineVariant),
            const SizedBox(height: 20),
            Text(
              'Sin visitas registradas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las visitas que registre portería\naparecerán aquí.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.outlineVariant,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 56, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
