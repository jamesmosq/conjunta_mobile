import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../models/work_order.dart';
import '../../providers/contractor_provider.dart';

class WorkOrderDetailScreen extends ConsumerWidget {
  const WorkOrderDetailScreen({super.key, required this.workOrder});

  final WorkOrder? workOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (workOrder == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Orden no encontrada')),
      );
    }
    final order = workOrder!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Orden #${order.id}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OrderInfoCard(order: order),
          const SizedBox(height: 16),
          _ActionsSection(order: order),
          const SizedBox(height: 16),
          _MaterialsSection(workOrderId: order.id),
        ],
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({required this.order});
  final WorkOrder order;

  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'es');

  @override
  Widget build(BuildContext context) {
    final mr = order.maintenanceRequest;
    String createdStr = '';
    try {
      createdStr =
          _dateFmt.format(DateTime.parse(order.createdAt).toLocal());
    } catch (_) {}

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip.forWorkOrderStatus(order.status),
                const Spacer(),
                if (mr?.urgency == 'urgent')
                  const StatusChip(label: 'Urgente', color: Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            if (mr != null) ...[
              _InfoRow(Icons.category_outlined, mr.typeLabel),
              if (mr.location != null)
                _InfoRow(Icons.location_on_outlined, mr.location!),
              if (mr.apartmentNumber != null)
                _InfoRow(
                  Icons.apartment_outlined,
                  '${mr.tower != null ? "Torre ${mr.tower} — " : ""}Apto ${mr.apartmentNumber}',
                ),
              const SizedBox(height: 12),
              Text(mr.description,
                  style: const TextStyle(fontSize: 14, height: 1.5)),
            ],
            const Divider(height: 24),
            _InfoRow(Icons.schedule_outlined, 'Creada: $createdStr'),
            if (order.estimatedArrivalAt != null)
              _InfoRow(
                Icons.directions_run_outlined,
                'Llegada estimada: ${_safeFmt(order.estimatedArrivalAt!)}',
              ),
          ],
        ),
      ),
    );
  }

  String _safeFmt(String dt) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm', 'es')
          .format(DateTime.parse(dt).toLocal());
    } catch (_) {
      return dt;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _ActionsSection extends ConsumerStatefulWidget {
  const _ActionsSection({required this.order});
  final WorkOrder order;

  @override
  ConsumerState<_ActionsSection> createState() => _ActionsSectionState();
}

class _ActionsSectionState extends ConsumerState<_ActionsSection> {
  bool _loading = false;

  Future<void> _accept() async {
    // Primero fecha
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date == null || !mounted) return;
    // Luego hora
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    final dt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    final dtStr =
        '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00';

    setState(() => _loading = true);
    try {
      await ref
          .read(activeWorkOrdersProvider.notifier)
          .accept(widget.order.id, dtStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden aceptada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goOnTheWay() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(activeWorkOrdersProvider.notifier)
          .goOnTheWay(widget.order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estado actualizado: En camino')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-read the current order state from provider
    final currentOrder = ref.watch(activeWorkOrdersProvider).value?.firstWhere(
          (o) => o.id == widget.order.id,
          orElse: () => widget.order,
        ) ??
        widget.order;

    final canAccept =
        currentOrder.status == 'pending' && currentOrder.acceptedAt == null;
    final canGoOnTheWay = currentOrder.status == 'pending' &&
        currentOrder.acceptedAt != null;

    if (!canAccept && !canGoOnTheWay) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Acciones',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            if (canAccept)
              FilledButton.icon(
                onPressed: _loading ? null : _accept,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Aceptar orden'),
              ),
            if (canGoOnTheWay) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _loading ? null : _goOnTheWay,
                icon: const Icon(Icons.directions_run_outlined),
                label: const Text('Voy en camino'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MaterialsSection extends ConsumerStatefulWidget {
  const _MaterialsSection({required this.workOrderId});
  final int workOrderId;

  @override
  ConsumerState<_MaterialsSection> createState() =>
      _MaterialsSectionState();
}

class _MaterialsSectionState extends ConsumerState<_MaterialsSection> {
  void _showAddMaterialSheet() {
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: 'un');
    final costCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Agregar material',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              decoration:
                  const InputDecoration(labelText: 'Descripción *'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Cantidad'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: unitCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Unidad'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: costCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Costo unitario (\$)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (descCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  final mat = {
                    'description': descCtrl.text.trim(),
                    'quantity':
                        double.tryParse(qtyCtrl.text) ?? 1,
                    'unit': unitCtrl.text.trim(),
                    if (costCtrl.text.isNotEmpty)
                      'unit_cost':
                          double.tryParse(costCtrl.text),
                  };
                  await ref
                      .read(workOrderMaterialsProvider(
                              widget.workOrderId)
                          .notifier)
                      .save([mat]);
                },
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync =
        ref.watch(workOrderMaterialsProvider(widget.workOrderId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Materiales',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAddMaterialSheet,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            AsyncValueWidget(
              value: materialsAsync,
              data: (materials) {
                if (materials.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Sin materiales registrados.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return Column(
                  children: materials
                      .map((m) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(m.description),
                            subtitle: Text(
                                '${m.quantity} ${m.unit}'),
                            trailing: m.totalCost != null
                                ? Text(
                                    NumberFormat.currency(
                                            locale: 'es_CO',
                                            symbol: '\$',
                                            decimalDigits: 0)
                                        .format(m.totalCost),
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600),
                                  )
                                : null,
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
