import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_repository.dart';
import '../models/user_notification.dart';

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<UserNotification>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier
    extends AsyncNotifier<List<UserNotification>> {
  @override
  Future<List<UserNotification>> build() async {
    return ref
        .read(notificationsRepositoryProvider)
        .getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> markRead(int id) async {
    await ref.read(notificationsRepositoryProvider).markRead(id);
    state = state.whenData(
      (list) => list
          .map((n) => n.id == id
              ? n.copyWith(readAt: DateTime.now().toIso8601String())
              : n)
          .toList(),
    );
  }

  Future<void> markAllRead() async {
    await ref.read(notificationsRepositoryProvider).markAllRead();
    state = state.whenData(
      (list) => list
          .map((n) => n.copyWith(readAt: DateTime.now().toIso8601String()))
          .toList(),
    );
  }
}

final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider).value ?? [];
  return notifs.where((n) => !n.isRead).length;
});
