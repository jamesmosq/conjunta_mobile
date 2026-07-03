import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/fcm_service.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../maintenance/providers/maintenance_provider.dart';
import '../../models/user_notification.dart';
import '../../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          notifsAsync.when(
            data: (list) {
              final hasUnread = list.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).markAllRead(),
                child: const Text('Leer todas'),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: notifsAsync,
        data: (notifs) {
          if (notifs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No tienes notificaciones.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: notifs.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 60),
              itemBuilder: (context, i) =>
                  _NotificationItem(notif: notifs[i]),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationItem extends ConsumerWidget {
  const _NotificationItem({required this.notif});

  final UserNotification notif;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    String timeStr = '';
    try {
      final dt = DateTime.parse(notif.createdAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) {
        timeStr = 'Hace ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        timeStr = 'Hace ${diff.inHours} h';
      } else {
        timeStr = DateFormat('dd/MM/yyyy', 'es').format(dt);
      }
    } catch (_) {}

    return InkWell(
      onTap: () {
        if (!notif.isRead) {
          ref.read(notificationsProvider.notifier).markRead(notif.id);
        }
        _showDetail(context, ref, notif);
      },
      child: Container(
        color: notif.isRead ? null : cs.primary.withValues(alpha: 0.05),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(
                    _iconFor(notif.type),
                    color: cs.primary,
                    size: 20,
                  ),
                ),
                if (!notif.isRead)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: TextStyle(
                      fontWeight:
                          notif.isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notif.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(timeStr,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref, UserNotification notif) {
    final cachedRequests =
        ref.read(maintenanceRequestsProvider).value;
    final (route, requestExtra) = FcmService.resolveRoute(
      notif.type,
      notif.data,
      cachedRequests: cachedRequests,
    );
    final hasDeepLink = route != '/notifications';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(notif.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(notif.body,
                  style: const TextStyle(fontSize: 15, height: 1.5)),
              if (hasDeepLink) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      if (requestExtra != null) {
                        GoRouter.of(context).push(route,
                            extra: requestExtra);
                      } else {
                        GoRouter.of(context).push(route);
                      }
                    },
                    child: const Text('Ir al detalle'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'charge_added' => Icons.receipt_outlined,
        'visit_registered' => Icons.person_pin_outlined,
        'package_arrived' => Icons.inventory_2_outlined,
        'assembly_convoked' => Icons.groups_outlined,
        'booking_approved' => Icons.event_available_outlined,
        'booking_rejected' => Icons.event_busy_outlined,
        'damage_report.status_updated' => Icons.build_outlined,
        _ => Icons.notifications_outlined,
      };
}
