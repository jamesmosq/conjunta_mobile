import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/contractor_repository.dart';
import '../models/work_order.dart';

// ── Active orders ─────────────────────────────────────────────────────────────

final activeWorkOrdersProvider =
    AsyncNotifierProvider<ActiveWorkOrdersNotifier, List<WorkOrder>>(
        ActiveWorkOrdersNotifier.new);

class ActiveWorkOrdersNotifier extends AsyncNotifier<List<WorkOrder>> {
  @override
  Future<List<WorkOrder>> build() async {
    return ref.read(contractorRepositoryProvider).getActiveOrders();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(contractorRepositoryProvider).getActiveOrders());
  }

  Future<void> accept(int id, String estimatedArrivalAt) async {
    final updated = await ref
        .read(contractorRepositoryProvider)
        .acceptOrder(id, estimatedArrivalAt);
    state = AsyncData(
      state.value?.map((o) => o.id == id ? updated : o).toList() ?? [],
    );
  }

  Future<void> goOnTheWay(int id) async {
    final updated =
        await ref.read(contractorRepositoryProvider).goOnTheWay(id);
    state = AsyncData(
      state.value?.map((o) => o.id == id ? updated : o).toList() ?? [],
    );
  }
}

// ── Order history ─────────────────────────────────────────────────────────────

final workOrderHistoryProvider =
    AsyncNotifierProvider<WorkOrderHistoryNotifier, List<WorkOrder>>(
        WorkOrderHistoryNotifier.new);

class WorkOrderHistoryNotifier extends AsyncNotifier<List<WorkOrder>> {
  @override
  Future<List<WorkOrder>> build() async {
    return ref.read(contractorRepositoryProvider).getHistory();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(contractorRepositoryProvider).getHistory());
  }
}

// ── Materials ─────────────────────────────────────────────────────────────────

final workOrderMaterialsProvider = AsyncNotifierProvider.family<
    WorkOrderMaterialsNotifier,
    List<WorkOrderMaterial>,
    int>(WorkOrderMaterialsNotifier.new);

class WorkOrderMaterialsNotifier
    extends FamilyAsyncNotifier<List<WorkOrderMaterial>, int> {
  @override
  Future<List<WorkOrderMaterial>> build(int arg) async {
    return ref.read(contractorRepositoryProvider).getMaterials(arg);
  }

  Future<void> save(List<Map<String, dynamic>> materials) async {
    await ref.read(contractorRepositoryProvider).saveMaterials(arg, materials);
    ref.invalidateSelf();
  }
}
