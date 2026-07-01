import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/areas_repository.dart';
import '../models/booking.dart';
import '../models/common_area.dart';

// ── Areas list ───────────────────────────────────────────────────────────────

final commonAreasProvider =
    AsyncNotifierProvider<CommonAreasNotifier, List<CommonArea>>(
        CommonAreasNotifier.new);

class CommonAreasNotifier extends AsyncNotifier<List<CommonArea>> {
  @override
  Future<List<CommonArea>> build() async {
    return ref.read(areasRepositoryProvider).getAreas();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(areasRepositoryProvider).getAreas());
  }
}

// ── My Bookings ───────────────────────────────────────────────────────────────

final myBookingsProvider =
    AsyncNotifierProvider<MyBookingsNotifier, List<Booking>>(
        MyBookingsNotifier.new);

class MyBookingsNotifier extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    return ref.read(areasRepositoryProvider).getMyBookings();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(areasRepositoryProvider).getMyBookings());
  }

  Future<void> cancel(int bookingId, String reason) async {
    await ref.read(areasRepositoryProvider).cancelBooking(bookingId, reason);
    state = AsyncData(
      state.value?.where((b) => b.id != bookingId).toList() ?? [],
    );
  }
}

// ── Selected area (for booking form) ─────────────────────────────────────────

final selectedAreaIdProvider = StateProvider<int?>((ref) => null);

final selectedAreaProvider =
    FutureProvider.family<CommonArea, int>((ref, id) async {
  return ref.read(areasRepositoryProvider).getArea(id);
});

// ── Availability for a given area + date ─────────────────────────────────────

typedef AreaDateKey = ({int areaId, String date});

final areaAvailabilityProvider =
    FutureProvider.family<List<Booking>, AreaDateKey>((ref, key) async {
  return ref
      .read(areasRepositoryProvider)
      .getAreaAvailability(key.areaId, key.date);
});
