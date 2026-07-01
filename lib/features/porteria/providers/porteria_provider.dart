import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../data/porteria_repository.dart';
import '../models/package.dart';
import '../models/pre_authorization.dart';
import '../models/visit.dart';

// ── Visits ──────────────────────────────────────────────────────────────────

final visitsProvider =
    AsyncNotifierProvider<VisitsNotifier, List<Visit>>(VisitsNotifier.new);

class VisitsNotifier extends AsyncNotifier<List<Visit>> {
  @override
  Future<List<Visit>> build() async {
    return ref.read(porteriaRepositoryProvider).getVisits();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(porteriaRepositoryProvider).getVisits());
  }
}

// ── Pre-Authorizations ──────────────────────────────────────────────────────

final preAuthorizationsProvider =
    AsyncNotifierProvider<PreAuthNotifier, List<PreAuthorization>>(
        PreAuthNotifier.new);

class PreAuthNotifier extends AsyncNotifier<List<PreAuthorization>> {
  @override
  Future<List<PreAuthorization>> build() async {
    final apartmentId =
        ref.read(authStateProvider).value?.apartmentId;
    if (apartmentId == null) return [];
    return ref
        .read(porteriaRepositoryProvider)
        .getPreAuthorizations(apartmentId);
  }

  Future<void> create(Map<String, dynamic> data) async {
    final apartmentId = ref.read(authStateProvider).value?.apartmentId;
    await ref.read(porteriaRepositoryProvider).createPreAuthorization({
      ...data,
      if (apartmentId != null) 'apartment_id': apartmentId,
    });
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await ref.read(porteriaRepositoryProvider).deletePreAuthorization(id);
    state = AsyncData(
      state.value?.where((p) => p.id != id).toList() ?? [],
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// ── Visit history (paginated) ─────────────────────────────────────────────────

class VisitHistoryState {
  const VisitHistoryState({
    this.visits = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 0,
    this.month,
    this.error,
  });

  final List<Visit> visits;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final DateTime? month;
  final String? error;

  VisitHistoryState copyWith({
    List<Visit>? visits,
    bool? isLoading,
    bool? hasMore,
    int? page,
    DateTime? month,
    String? error,
    bool clearError = false,
  }) =>
      VisitHistoryState(
        visits: visits ?? this.visits,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        month: month ?? this.month,
        error: clearError ? null : (error ?? this.error),
      );
}

final visitHistoryProvider =
    StateNotifierProvider<VisitHistoryNotifier, VisitHistoryState>(
  (ref) => VisitHistoryNotifier(ref),
);

class VisitHistoryNotifier extends StateNotifier<VisitHistoryState> {
  VisitHistoryNotifier(this._ref) : super(const VisitHistoryState()) {
    loadMore();
  }

  final Ref _ref;

  PorteriaRepository get _repo => _ref.read(porteriaRepositoryProvider);

  /// Loads the next page, appending to the existing list.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final nextPage = state.page + 1;
    final (dateFrom, dateTo) = _monthRange(state.month);

    try {
      final result = await _repo.getVisitHistory(
        page: nextPage,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      state = state.copyWith(
        visits: [...state.visits, ...result.visits],
        hasMore: result.hasMore,
        page: nextPage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo cargar el historial.',
      );
    }
  }

  /// Resets state to page 0 with a new month filter and reloads.
  Future<void> filterByMonth(DateTime? month) async {
    state = VisitHistoryState(month: month);
    await loadMore();
  }

  /// Full refresh keeping the current month filter.
  Future<void> refresh() async {
    state = VisitHistoryState(month: state.month);
    await loadMore();
  }

  static (String?, String?) _monthRange(DateTime? month) {
    if (month == null) return (null, null);
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);
    return (
      '${from.year}-${from.month.toString().padLeft(2, '0')}-01',
      '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}',
    );
  }
}

// ── Packages ─────────────────────────────────────────────────────────────────

final packagesProvider =
    AsyncNotifierProvider<PackagesNotifier, List<Package>>(PackagesNotifier.new);

class PackagesNotifier extends AsyncNotifier<List<Package>> {
  @override
  Future<List<Package>> build() async {
    return ref.read(porteriaRepositoryProvider).getPackages();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(porteriaRepositoryProvider).getPackages());
  }
}
