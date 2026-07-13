import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../data/account_repository.dart';
import '../../models/account_statement.dart';
import '../../models/charge.dart';
import '../../providers/account_provider.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  String _statusFilter = 'pending'; // 'all' | 'pending' | 'paid'
  String? _typeFilter;              // null = all, or charge.type

  final _moneyFmt = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  List<Charge> _filtered(List<Charge> charges) {
    return charges.where((c) {
      final statusOk = switch (_statusFilter) {
        'pending' => !c.isPaid,
        'paid' => c.isPaid,
        _ => true,
      };
      final typeOk = _typeFilter == null || c.type == _typeFilter;
      return statusOk && typeOk;
    }).toList()
      ..sort((a, b) {
        // Overdue first, then by due date ascending
        if (a.isOverdue && !b.isOverdue) return -1;
        if (!a.isOverdue && b.isOverdue) return 1;
        return a.dueDate.compareTo(b.dueDate);
      });
  }

  @override
  Widget build(BuildContext context) {
    final statementAsync = ref.watch(accountStatementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de cuenta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () =>
                ref.read(accountStatementProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Paz y salvo',
            onPressed: () => context.push('/account/paz-y-salvo'),
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: statementAsync,
        data: (statement) {
          if (statement == null) {
            return const Center(
              child: Text('No tienes apartamento asignado.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(accountStatementProvider.notifier).refresh(),
            child: _Body(
              statement: statement,
              statusFilter: _statusFilter,
              typeFilter: _typeFilter,
              moneyFmt: _moneyFmt,
              filtered: _filtered(statement.charges),
              onStatusFilter: (v) => setState(() => _statusFilter = v),
              onTypeFilter: (v) => setState(() => _typeFilter = v),
            ),
          );
        },
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.statement,
    required this.statusFilter,
    required this.typeFilter,
    required this.moneyFmt,
    required this.filtered,
    required this.onStatusFilter,
    required this.onTypeFilter,
  });

  final AccountStatement statement;
  final String statusFilter;
  final String? typeFilter;
  final NumberFormat moneyFmt;
  final List<Charge> filtered;
  final ValueChanged<String> onStatusFilter;
  final ValueChanged<String?> onTypeFilter;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Balance card ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: _BalanceCard(
            statement: statement,
            moneyFmt: moneyFmt,
          ),
        ),

        // ── Breakdown ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _BreakdownRow(
            charges: statement.charges,
            moneyFmt: moneyFmt,
            selectedType: typeFilter,
            onTap: onTypeFilter,
          ),
        ),

        // ── Status filter (SegmentedButton) ──────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'pending',
                    label: Text('Pendientes'),
                    icon: Icon(Icons.pending_actions_outlined, size: 16)),
                ButtonSegment(
                    value: 'all',
                    label: Text('Todos'),
                    icon: Icon(Icons.list_outlined, size: 16)),
                ButtonSegment(
                    value: 'paid',
                    label: Text('Pagados'),
                    icon: Icon(Icons.check_circle_outline, size: 16)),
              ],
              selected: {statusFilter},
              onSelectionChanged: (s) => onStatusFilter(s.first),
            ),
          ),
        ),

        // ── Charges list ─────────────────────────────────────────
        if (filtered.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'No hay cargos en este filtro.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _ChargeCard(
                charge: filtered[i],
                apartmentId: statement.apartmentId,
                moneyFmt: moneyFmt,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Balance card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.statement, required this.moneyFmt});

  final AccountStatement statement;
  final NumberFormat moneyFmt;

  @override
  Widget build(BuildContext context) {
    final isOk = statement.pazYSalvo;
    final overdue =
        statement.charges.where((c) => c.isOverdue).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOk
              ? [const Color(0xFF1B5E20), const Color(0xFF388E3C)]
              : [const Color(0xFFB71C1C), const Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOk
                          ? Icons.verified_outlined
                          : Icons.warning_amber_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOk ? 'Paz y Salvo' : 'Con deuda',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (overdue > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(80),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$overdue vencido${overdue > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Saldo pendiente',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            moneyFmt.format(statement.balanceDue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Breakdown row ────────────────────────────────────────────────────────────

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.charges,
    required this.moneyFmt,
    required this.selectedType,
    required this.onTap,
  });

  final List<Charge> charges;
  final NumberFormat moneyFmt;
  final String? selectedType;
  final ValueChanged<String?> onTap;

  @override
  Widget build(BuildContext context) {
    // Aggregate pending balance by type
    final byType = <String, double>{};
    for (final c in charges.where((c) => !c.isPaid)) {
      byType[c.type] = (byType[c.type] ?? 0) + c.balanceDue;
    }
    if (byType.isEmpty) return const SizedBox(height: 8);

    final items = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final entry = items[i];
          final selected = selectedType == entry.key;
          final label = _shortLabel(entry.key);
          final color = _colorFor(entry.key);
          return GestureDetector(
            onTap: () => onTap(selected ? null : entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? color.withAlpha(40)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: selected
                    ? Border.all(color: color, width: 1.5)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? color
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    moneyFmt.format(entry.value),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: selected
                            ? color
                            : Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _shortLabel(String type) => switch (type) {
        'admin_fee' => 'Cuota admin',
        'fine' => 'Multas',
        'interest' => 'Intereses',
        'extraordinary_fee' => 'Extraordinaria',
        'area_booking' => 'Área común',
        _ => type,
      };

  Color _colorFor(String type) => switch (type) {
        'admin_fee' => Colors.blue,
        'fine' => Colors.red,
        'interest' => Colors.orange,
        'extraordinary_fee' => Colors.purple,
        'area_booking' => Colors.teal,
        _ => Colors.grey,
      };
}

// ─── Charge card ──────────────────────────────────────────────────────────────

class _ChargeCard extends ConsumerStatefulWidget {
  const _ChargeCard({
    required this.charge,
    required this.apartmentId,
    required this.moneyFmt,
  });

  final Charge charge;
  final int apartmentId;
  final NumberFormat moneyFmt;

  @override
  ConsumerState<_ChargeCard> createState() => _ChargeCardState();
}

class _ChargeCardState extends ConsumerState<_ChargeCard> {
  bool _downloading = false;

  Charge get charge => widget.charge;

  Future<void> _downloadReceipt() async {
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(accountRepositoryProvider)
          .downloadReceipt(widget.apartmentId, charge.id);
      final tmpDir = Directory.systemTemp;
      final file = File(
          '${tmpDir.path}/recibo_${charge.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo descargar el recibo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChargeDetailSheet(
        charge: charge,
        apartmentId: widget.apartmentId,
        moneyFmt: widget.moneyFmt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM yyyy', 'es');
    String dueStr;
    try {
      dueStr = dateFmt.format(DateTime.parse(charge.dueDate));
    } catch (_) {
      dueStr = charge.dueDate;
    }

    final borderColor = charge.isOverdue
        ? Colors.red
        : charge.isPaid
            ? Colors.green.withAlpha(80)
            : cs.outlineVariant;

    return InkWell(
      onTap: _showDetail,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: charge.isOverdue ? 1.5 : 1),
          color: charge.isPaid
              ? cs.surfaceContainerHighest.withAlpha(80)
              : cs.surface,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TypeBadge(type: charge.type),
                const SizedBox(width: 8),
                if (charge.isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withAlpha(80)),
                    ),
                    child: const Text(
                      'VENCIDO',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.red,
                          letterSpacing: 0.8),
                    ),
                  ),
                const Spacer(),
                StatusChip.forChargeStatus(charge.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              charge.description,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: charge.isPaid
                    ? cs.onSurfaceVariant
                    : cs.onSurface,
              ),
            ),
            if (charge.periodLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                charge.periodLabel!,
                style: TextStyle(fontSize: 12, color: cs.outlineVariant),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: cs.outlineVariant),
                const SizedBox(width: 4),
                Text(
                  'Vence: $dueStr',
                  style: TextStyle(
                      fontSize: 12,
                      color: charge.isOverdue
                          ? Colors.red
                          : cs.onSurfaceVariant),
                ),
                const Spacer(),
                if (!charge.isPaid)
                  Text(
                    'Pendiente: ${widget.moneyFmt.format(charge.balanceDue)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.red),
                  )
                else
                  Text(
                    widget.moneyFmt.format(charge.amount),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.outlineVariant),
                  ),
              ],
            ),
            if (charge.isPaid) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _downloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton.icon(
                        onPressed: _downloadReceipt,
                        icon: const Icon(Icons.picture_as_pdf_outlined,
                            size: 14),
                        label: const Text('Recibo', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'admin_fee' => ('Cuota', Colors.blue),
      'fine' => ('Multa', Colors.red),
      'interest' => ('Interés', Colors.orange),
      'extraordinary_fee' => ('Extraord.', Colors.purple),
      'area_booking' => ('Área', Colors.teal),
      _ => (type, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }
}

// ─── Charge detail bottom sheet ───────────────────────────────────────────────

class _ChargeDetailSheet extends ConsumerStatefulWidget {
  const _ChargeDetailSheet({
    required this.charge,
    required this.apartmentId,
    required this.moneyFmt,
  });

  final Charge charge;
  final int apartmentId;
  final NumberFormat moneyFmt;

  @override
  ConsumerState<_ChargeDetailSheet> createState() =>
      _ChargeDetailSheetState();
}

class _ChargeDetailSheetState extends ConsumerState<_ChargeDetailSheet> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(accountRepositoryProvider)
          .downloadReceipt(widget.apartmentId, widget.charge.id);
      final tmpDir = Directory.systemTemp;
      final file = File(
          '${tmpDir.path}/recibo_${widget.charge.id}.pdf');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo descargar el recibo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final charge = widget.charge;
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'es');
    final fmt = widget.moneyFmt;

    String dueFmt;
    try {
      dueFmt = dateFmt.format(DateTime.parse(charge.dueDate));
    } catch (_) {
      dueFmt = charge.dueDate;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _TypeBadge(type: charge.type),
              const SizedBox(width: 8),
              if (charge.isOverdue)
                const Text('VENCIDO',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              const Spacer(),
              StatusChip.forChargeStatus(charge.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            charge.description,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (charge.periodLabel != null)
            Text(
              charge.periodLabel!,
              style:
                  TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          _DetailRow(label: 'Total', value: fmt.format(charge.amount)),
          const SizedBox(height: 8),
          _DetailRow(
              label: 'Pagado', value: fmt.format(charge.paidAmount)),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Saldo',
            value: fmt.format(charge.balanceDue),
            valueColor: charge.balanceDue > 0 ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 8),
          _DetailRow(label: 'Vence', value: dueFmt),
          const SizedBox(height: 24),
          if (charge.isPaid)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _downloading ? null : _download,
                icon: _downloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Descargar recibo'),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: cs.onErrorContainer, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Para cancelar este cargo contacta a la administración o realiza el pago en caja.',
                      style: TextStyle(
                          fontSize: 13, color: cs.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
