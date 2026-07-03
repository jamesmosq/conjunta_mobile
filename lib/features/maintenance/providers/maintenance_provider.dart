import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/maintenance_repository.dart';
import '../models/maintenance_request.dart';

final maintenanceRequestsProvider = AsyncNotifierProvider<
    MaintenanceRequestsNotifier, List<MaintenanceRequest>>(
  MaintenanceRequestsNotifier.new,
);

class MaintenanceRequestsNotifier
    extends AsyncNotifier<List<MaintenanceRequest>> {
  @override
  Future<List<MaintenanceRequest>> build() async {
    return ref.read(maintenanceRepositoryProvider).getMyRequests();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(maintenanceRepositoryProvider).getMyRequests());
  }

  Future<void> create(Map<String, dynamic> data) async {
    final request = await ref
        .read(maintenanceRepositoryProvider)
        .createRequest(data);
    state = AsyncData([request, ...?state.value]);
  }
}

final timelineProvider =
    FutureProvider.family<List<TimelineEntry>, int>((ref, requestId) async {
  return ref.read(maintenanceRepositoryProvider).getTimeline(requestId);
});
