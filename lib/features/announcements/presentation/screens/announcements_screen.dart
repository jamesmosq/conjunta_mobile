import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/announcement.dart';
import '../../providers/announcements_provider.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementsProvider);
    final unread = state.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Comunicados'),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              _UnreadBadge(count: unread),
            ],
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed:
                  () => ref.read(announcementsProvider.notifier).markAllRead(),
              child: const Text('Leer todos'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _FilterBar(unreadOnly: state.unreadOnly),
        ),
      ),
      body: _Body(state: state),
    );
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.unreadOnly});

  final bool unreadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'Todos',
            selected: !unreadOnly,
            onTap:
                () => ref
                    .read(announcementsProvider.notifier)
                    .setUnreadOnly(false),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'No leídos',
            selected: unreadOnly,
            onTap:
                () => ref
                    .read(announcementsProvider.notifier)
                    .setUnreadOnly(true),
          ),
        ],
      ),
    );
  }
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
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

  final AnnouncementsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.items.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty && state.error != null) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref.read(announcementsProvider.notifier).loadMore(),
      );
    }

    if (state.items.isEmpty) {
      return _EmptyState(unreadOnly: state.unreadOnly);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(announcementsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: state.items.length + 1,
        itemBuilder: (context, i) {
          if (i == state.items.length) {
            return _LoadMoreFooter(
              isLoading: state.isLoading,
              hasMore: state.hasMore,
              error: state.error,
              onLoadMore:
                  () => ref.read(announcementsProvider.notifier).loadMore(),
            );
          }
          return _AnnouncementCard(announcement: state.items[i]);
        },
      ),
    );
  }
}

// ─── Announcement card ────────────────────────────────────────────────────────

class _AnnouncementCard extends ConsumerWidget {
  const _AnnouncementCard({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final a = announcement;
    final borderColor = _importanceColor(a.importance);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: a.isRead ? cs.surface : cs.primary.withAlpha(8),
        border: Border.all(color: cs.outlineVariant.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, color: borderColor),
          Expanded(
            child: InkWell(
              onTap: () {
                if (!a.isRead) {
                  ref.read(announcementsProvider.notifier).markRead(a.id);
                }
                _showDetail(context, a);
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ImportanceBadge(importance: a.importance),
                        if (a.category != null) ...[
                          const SizedBox(width: 6),
                          _CategoryBadge(label: a.categoryLabel),
                        ],
                        const Spacer(),
                        if (!a.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.title,
                      style: TextStyle(
                        fontWeight:
                            a.isRead ? FontWeight.w500 : FontWeight.w700,
                        fontSize: 14,
                        color: a.isRead ? cs.onSurfaceVariant : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 12,
                          color: cs.outlineVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _relativeTime(a.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.outlineVariant,
                          ),
                        ),
                        if (a.author != null) ...[
                          const SizedBox(width: 10),
                          Icon(
                            Icons.person_outline,
                            size: 12,
                            color: cs.outlineVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            a.author!,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.outlineVariant,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (a.isRead)
                          Icon(
                            Icons.done_all,
                            size: 14,
                            color: cs.outlineVariant,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _importanceColor(String importance) => switch (importance) {
    'urgent' => Colors.red,
    'normal' => Colors.blue,
    _ => Colors.grey,
  };

  static String _relativeTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
      if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
      return DateFormat('dd/MM/yyyy', 'es').format(dt);
    } catch (_) {
      return '';
    }
  }
}

// ─── Badges ───────────────────────────────────────────────────────────────────

class _ImportanceBadge extends StatelessWidget {
  const _ImportanceBadge({required this.importance});
  final String importance;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (importance) {
      'urgent' => ('URGENTE', Colors.red),
      'normal' => ('Comunicado', Colors.blue),
      _ => ('Informativo', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cs.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: cs.onError,
        ),
      ),
    );
  }
}

// ─── Detail bottom sheet ──────────────────────────────────────────────────────

void _showDetail(BuildContext context, Announcement a) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (_) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder:
              (_, ctrl) => ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _ImportanceBadge(importance: a.importance),
                      if (a.category != null) ...[
                        const SizedBox(width: 6),
                        _CategoryBadge(label: a.categoryLabel),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    a.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 13,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat(
                          'dd \'de\' MMMM \'de\' yyyy, HH:mm',
                          'es',
                        ).format(
                          DateTime.tryParse(a.createdAt)?.toLocal() ??
                              DateTime.now(),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                  if (a.author != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 13,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          a.author!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    a.body,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                ],
              ),
        ),
  );
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
            Text(
              error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onLoadMore, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No hay más comunicados',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
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
  const _EmptyState({required this.unreadOnly});
  final bool unreadOnly;

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
              unreadOnly
                  ? Icons.mark_email_read_outlined
                  : Icons.campaign_outlined,
              size: 72,
              color: cs.outlineVariant,
            ),
            const SizedBox(height: 20),
            Text(
              unreadOnly ? '¡Todo al día!' : 'Sin comunicados',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              unreadOnly
                  ? 'Has leído todos los comunicados.'
                  : 'La administración publicará comunicados aquí.',
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
          Icon(
            Icons.error_outline,
            size: 56,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
