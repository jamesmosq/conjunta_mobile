import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/parking_repository.dart';
import '../models/parking_spot.dart';

final parkingSpotsProvider =
    AsyncNotifierProvider<ParkingSpotsNotifier, List<ParkingSpot>>(
        ParkingSpotsNotifier.new);

class ParkingSpotsNotifier extends AsyncNotifier<List<ParkingSpot>> {
  @override
  Future<List<ParkingSpot>> build() async {
    return ref.read(parkingRepositoryProvider).getSpots();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(parkingRepositoryProvider).getSpots());
  }

  Future<void> assign(int spotId, int visitId) async {
    final updated =
        await ref.read(parkingRepositoryProvider).assign(spotId, visitId);
    state = AsyncData([
      for (final s in state.value ?? []) if (s.id == spotId) updated else s,
    ]);
  }

  Future<void> release(int spotId) async {
    final updated = await ref.read(parkingRepositoryProvider).release(spotId);
    state = AsyncData([
      for (final s in state.value ?? []) if (s.id == spotId) updated else s,
    ]);
  }
}
