import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/blacklist_repository.dart';
import '../models/blacklist_entry.dart';

final blacklistProvider =
    AsyncNotifierProvider<BlacklistNotifier, List<BlacklistEntry>>(
        BlacklistNotifier.new);

class BlacklistNotifier extends AsyncNotifier<List<BlacklistEntry>> {
  @override
  Future<List<BlacklistEntry>> build() async {
    return ref.read(blacklistRepositoryProvider).getList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(blacklistRepositoryProvider).getList());
  }
}
