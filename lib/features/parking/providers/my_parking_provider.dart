import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/parking_repository.dart';
import '../models/parking_spot.dart';

class MyParkingState {
  const MyParkingState({
    this.mySpots = const [],
    this.availableToClaim = const [],
  });

  final List<ParkingSpot> mySpots;
  final List<ParkingSpot> availableToClaim;
}

final myParkingProvider =
    AsyncNotifierProvider<MyParkingNotifier, MyParkingState>(
        MyParkingNotifier.new);

class MyParkingNotifier extends AsyncNotifier<MyParkingState> {
  @override
  Future<MyParkingState> build() async {
    return _load();
  }

  Future<MyParkingState> _load() async {
    final repo = ref.read(parkingRepositoryProvider);
    final results = await Future.wait([
      repo.getMySpots(),
      repo.getAvailableToClaim(),
    ]);
    final mySpots = results[0];
    final myIds = mySpots.map((s) => s.id).toSet();
    // El propio espacio ya se muestra en "Mi parqueadero" — no duplicarlo
    // en "Disponibles para reclamar" cuando está vacío.
    final availableToClaim =
        results[1].where((s) => !myIds.contains(s.id)).toList();
    return MyParkingState(
      mySpots: mySpots,
      availableToClaim: availableToClaim,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> vacate(int spotId, String reason) async {
    await ref.read(parkingRepositoryProvider).vacate(spotId, reason);
    await refresh();
  }

  Future<void> occupy(int spotId) async {
    await ref.read(parkingRepositoryProvider).occupy(spotId);
    await refresh();
  }

  Future<void> claim(int spotId) async {
    await ref.read(parkingRepositoryProvider).claim(spotId);
    await refresh();
  }
}
