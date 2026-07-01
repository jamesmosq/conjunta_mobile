import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pqrs_repository.dart';
import '../models/pqrs_item.dart';

final pqrsProvider =
    AsyncNotifierProvider<PqrsNotifier, List<PqrsItem>>(PqrsNotifier.new);

class PqrsNotifier extends AsyncNotifier<List<PqrsItem>> {
  @override
  Future<List<PqrsItem>> build() async {
    return ref.read(pqrsRepositoryProvider).getMyPqrs();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> create(Map<String, dynamic> data) async {
    final created = await ref.read(pqrsRepositoryProvider).createPqrs(data);
    state = state.whenData((list) => [created, ...list]);
  }
}

final pqrsStatusFilterProvider = StateProvider<String>((ref) => 'all');
