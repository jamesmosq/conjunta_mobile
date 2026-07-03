import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../models/pre_authorization.dart';
import '../../providers/porteria_provider.dart';

class PreAuthScreen extends ConsumerWidget {
  const PreAuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(preAuthorizationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-autorizaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Actualizar',
            onPressed: () => ref.read(preAuthorizationsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: AsyncValueWidget<List<PreAuthorization>>(
        value: asyncList,
        data: (list) => _Body(list: list),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/porteria/pre-auth/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.list});

  final List<PreAuthorization> list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    PreAuthStatus status(PreAuthorization p) {
      if (!p.isActive) return PreAuthStatus.expired;
      if (p.isValidNow) return PreAuthStatus.active;
      final expires = _parseDate(p.expiresAt);
      if (expires != null && expires.isBefore(today)) return PreAuthStatus.expired;
      final expected = _parseDate(p.expectedAt);
      if (expected != null && expected.isAfter(today)) return PreAuthStatus.upcoming;
      return PreAuthStatus.active;
    }

    final upcoming = list.where((p) => status(p) == PreAuthStatus.upcoming).toList()
      ..sort((a, b) {
        final da = _parseDate(a.expectedAt) ?? DateTime(2000);
        final db = _parseDate(b.expectedAt) ?? DateTime(2000);
        return da.compareTo(db);
      });
    final active = list.where((p) => status(p) == PreAuthStatus.active).toList()
      ..sort((a, b) {
        final da = _parseDate(a.expiresAt) ?? DateTime(9999);
        final db = _parseDate(b.expiresAt) ?? DateTime(9999);
        return da.compareTo(db);
      });
    final expired = list.where((p) => status(p) == PreAuthStatus.expired).toList()
      ..sort((a, b) {
        final da = _parseDate(a.expiresAt) ?? DateTime(2000);
        final db = _parseDate(b.expiresAt) ?? DateTime(2000);
        return db.compareTo(da);
      });

    if (list.isEmpty) {
      return _EmptyState(
        onTap: () => context.push('/porteria/pre-auth/new'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(preAuthorizationsProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (active.isNotEmpty) ...[
            _SectionHeader(
              label: 'Vigentes',
              count: active.length,
              color: Colors.green,
            ),
            ...active.map(
              (p) => _PreAuthCard(auth: p, status: PreAuthStatus.active),
            ),
            const SizedBox(height: 8),
          ],
          if (upcoming.isNotEmpty) ...[
            _SectionHeader(
              label: 'Próximas',
              count: upcoming.length,
              color: Colors.blue,
            ),
            ...upcoming.map(
              (p) => _PreAuthCard(auth: p, status: PreAuthStatus.upcoming),
            ),
            const SizedBox(height: 8),
          ],
          if (expired.isNotEmpty) ...[
            _SectionHeader(
              label: 'Vencidas',
              count: expired.length,
              color: Colors.grey,
            ),
            ...expired.map(
              (p) => _PreAuthCard(auth: p, status: PreAuthStatus.expired),
            ),
          ],
        ],
      ),
    );
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }
}

// ─── Status enum ─────────────────────────────────────────────────────────────

enum PreAuthStatus { upcoming, active, expired }

extension PreAuthStatusX on PreAuthStatus {
  String get label => switch (this) {
        PreAuthStatus.upcoming => 'Próxima',
        PreAuthStatus.active => 'Vigente',
        PreAuthStatus.expired => 'Vencida',
      };

  Color get color => switch (this) {
        PreAuthStatus.upcoming => Colors.blue,
        PreAuthStatus.active => Colors.green,
        PreAuthStatus.expired => Colors.grey,
      };

  IconData get icon => switch (this) {
        PreAuthStatus.upcoming => Icons.schedule_outlined,
        PreAuthStatus.active => Icons.verified_user_outlined,
        PreAuthStatus.expired => Icons.timer_off_outlined,
      };
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pre-auth card ────────────────────────────────────────────────────────────

class _PreAuthCard extends ConsumerWidget {
  const _PreAuthCard({required this.auth, required this.status});

  final PreAuthorization auth;
  final PreAuthStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yyyy', 'es');
    final cs = Theme.of(context).colorScheme;
    final dimmed = status == PreAuthStatus.expired;

    return Dismissible(
      key: ValueKey(auth.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      confirmDismiss: (_) => _confirmDelete(context, auth.visitorName),
      onDismissed: (_) async {
        await ref
            .read(preAuthorizationsProvider.notifier)
            .delete(auth.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pre-autorización de ${auth.visitorName} eliminada'),
              action: SnackBarAction(label: 'OK', onPressed: () {}),
            ),
          );
        }
      },
      child: Opacity(
        opacity: dimmed ? 0.55 : 1.0,
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: status.color.withAlpha(30),
                      child: Icon(status.icon,
                          color: status.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.visitorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (auth.documentNumber != null)
                            Text(
                              'Doc: ${auth.documentNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      auth.isRecurring
                          ? Icons.repeat_outlined
                          : Icons.date_range_outlined,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _dateLabel(fmt, auth),
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ),
                    _RemainingDays(auth: auth, status: status),
                  ],
                ),
                if (auth.relationType != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.group_outlined,
                          size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        auth.relationTypeLabel,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _dateLabel(DateFormat fmt, PreAuthorization auth) {
    if (auth.isRecurring) {
      final from = auth.allowedFrom ?? '';
      final until = auth.allowedUntil ?? '';
      return 'Recurrente${from.isNotEmpty ? ' · $from – $until' : ''}';
    }
    if (auth.expectedAt != null) {
      final d = _parseDate(auth.expectedAt);
      if (d != null) return 'Esperado: ${fmt.format(d)}';
    }
    if (auth.expiresAt != null) {
      final d = _parseDate(auth.expiresAt);
      if (d != null) return 'Vence: ${fmt.format(d)}';
    }
    return auth.arrivalModeLabel;
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar pre-autorización'),
        content:
            Text('¿Deseas eliminar la pre-autorización de $name?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PreAuthStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withAlpha(25),
        border: Border.all(color: status.color.withAlpha(80)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}

class _RemainingDays extends StatelessWidget {
  const _RemainingDays({required this.auth, required this.status});

  final PreAuthorization auth;
  final PreAuthStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == PreAuthStatus.expired || auth.isRecurring) {
      return const SizedBox.shrink();
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    DateTime? target;
    String prefix;
    if (status == PreAuthStatus.upcoming) {
      target = _parseDate(auth.expectedAt);
      prefix = 'Inicia en';
    } else {
      target = _parseDate(auth.expiresAt);
      prefix = 'Vence en';
    }

    if (target == null) return const SizedBox.shrink();

    final days = target.difference(todayDate).inDays;

    final color = days <= 1
        ? Colors.red
        : days <= 3
            ? Colors.orange
            : Colors.green;

    return Text(
      '$prefix $days d',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 72,
              color: cs.outlineVariant,
            ),
            const SizedBox(height: 20),
            Text(
              'Sin pre-autorizaciones',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una pre-autorización para que portería\npermita el acceso a tus visitantes sin\nnecesidad de llamarte.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.outlineVariant,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add),
              label: const Text('Crear primera pre-autorización'),
            ),
          ],
        ),
      ),
    );
  }
}
