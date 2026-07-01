import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../models/work_order.dart';
import '../../providers/contractor_provider.dart';

class WorkOrdersScreen extends ConsumerWidget {
  const WorkOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis órdenes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activas', icon: Icon(Icons.assignment_outlined)),
              Tab(text: 'Historial', icon: Icon(Icons.history_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ActiveOrdersTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _ActiveOrdersTab extends ConsumerWidget {
  const _ActiveOrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(activeWorkOrdersProvider);
    return AsyncValueWidget<List<WorkOrder>>(
      value: ordersAsync,
      data: (orders) => orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No tienes órdenes activas.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(activeWorkOrdersProvider.notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _WorkOrderCard(order: orders[i]),
              ),
            ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workOrderHistoryProvider);
    return AsyncValueWidget<List<WorkOrder>>(
      value: historyAsync,
      data: (orders) => orders.isEmpty
          ? const Center(
              child: Text('No hay órdenes completadas.',
                  style: TextStyle(color: Colors.grey)))
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(workOrderHistoryProvider.notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _WorkOrderCard(order: orders[i]),
              ),
            ),
    );
  }
}

class _WorkOrderCard extends StatelessWidget {
  const _WorkOrderCard({required this.order});
  final WorkOrder order;

  static final _dateFmt = DateFormat('dd/MM/yyyy', 'es');

  IconData get _typeIcon {
    final type = order.maintenanceRequest?.type ?? '';
    return switch (type) {
      'plomeria' => Icons.water_drop_outlined,
      'electricidad' => Icons.electrical_services_outlined,
      'estructura' => Icons.foundation_outlined,
      'gas' => Icons.local_fire_department_outlined,
      _ => Icons.build_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final mr = order.maintenanceRequest;
    String dateStr = '';
    try {
      dateStr = _dateFmt.format(DateTime.parse(order.createdAt));
    } catch (_) {}

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/contractor/orders/detail', extra: order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_typeIcon,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mr?.typeLabel ?? 'Orden #${order.id}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        if (mr?.apartmentNumber != null)
                          Text(
                            '${mr!.tower != null ? "Torre ${mr.tower} — " : ""}Apto ${mr.apartmentNumber}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  StatusChip.forWorkOrderStatus(order.status),
                ],
              ),
              if (mr?.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(mr!.location!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (mr?.urgency == 'urgent') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Urgente',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
