import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/account_repository.dart';
import '../models/account_statement.dart';
import '../models/charge.dart';

final accountStatementProvider =
    AsyncNotifierProvider<AccountStatementNotifier, AccountStatement?>(
  AccountStatementNotifier.new,
);

class AccountStatementNotifier extends AsyncNotifier<AccountStatement?> {
  @override
  Future<AccountStatement?> build() async {
    final apartmentId = ref.watch(authStateProvider).value?.apartmentId;
    if (apartmentId == null) return null;
    return ref.read(accountRepositoryProvider).getStatement(apartmentId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final selectedChargeProvider = StateProvider<Charge?>((ref) => null);
