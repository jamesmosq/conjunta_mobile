import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/staff_badge_repository.dart';
import '../models/staff_badge.dart';

final myBadgeProvider =
    AsyncNotifierProvider<MyBadgeNotifier, StaffBadge>(MyBadgeNotifier.new);

class MyBadgeNotifier extends AsyncNotifier<StaffBadge> {
  @override
  Future<StaffBadge> build() {
    return ref.read(staffBadgeRepositoryProvider).getMyBadge();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(staffBadgeRepositoryProvider).getMyBadge(),
    );
  }

  Future<void> regenerate() async {
    state = await AsyncValue.guard(
      () => ref.read(staffBadgeRepositoryProvider).regenerate(),
    );
  }
}
