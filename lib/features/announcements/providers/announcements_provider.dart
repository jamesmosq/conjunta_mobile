import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/announcements_repository.dart';
import '../models/announcement.dart';

// ── State ────────────────────────────────────────────────────────────────────

class AnnouncementsState {
  const AnnouncementsState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 0,
    this.unreadOnly = false,
    this.error,
  });

  final List<Announcement> items;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final bool unreadOnly;
  final String? error;

  int get unreadCount => items.where((a) => !a.isRead).length;

  AnnouncementsState copyWith({
    List<Announcement>? items,
    bool? isLoading,
    bool? hasMore,
    int? page,
    bool? unreadOnly,
    String? error,
    bool clearError = false,
  }) =>
      AnnouncementsState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        unreadOnly: unreadOnly ?? this.unreadOnly,
        error: clearError ? null : (error ?? this.error),
      );
}

// ── Provider ─────────────────────────────────────────────────────────────────

final announcementsProvider =
    StateNotifierProvider<AnnouncementsNotifier, AnnouncementsState>(
  (ref) => AnnouncementsNotifier(ref)..loadMore(),
);

final announcementsUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(announcementsProvider).unreadCount;
});

class AnnouncementsNotifier extends StateNotifier<AnnouncementsState> {
  AnnouncementsNotifier(this._ref) : super(const AnnouncementsState());

  final Ref _ref;

  AnnouncementsRepository get _repo =>
      _ref.read(announcementsRepositoryProvider);

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final nextPage = state.page + 1;
    try {
      final result = await _repo.getAnnouncements(
        page: nextPage,
        unreadOnly: state.unreadOnly,
      );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        hasMore: result.hasMore,
        page: nextPage,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudieron cargar los comunicados.',
      );
    }
  }

  Future<void> setUnreadOnly(bool value) async {
    state = AnnouncementsState(unreadOnly: value);
    await loadMore();
  }

  Future<void> refresh() async {
    state = AnnouncementsState(unreadOnly: state.unreadOnly);
    await loadMore();
  }

  Future<void> markRead(int id) async {
    await _repo.markRead(id);
    state = state.copyWith(
      items: state.items
          .map((a) => a.id == id
              ? a.copyWith(readAt: DateTime.now().toIso8601String())
              : a)
          .toList(),
    );
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    final now = DateTime.now().toIso8601String();
    state = state.copyWith(
      items: state.items.map((a) => a.copyWith(readAt: now)).toList(),
    );
  }
}
