import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../models/pqrs_item.dart';
import '../../providers/pqrs_provider.dart';

class PqrsScreen extends ConsumerWidget {
  const PqrsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pqrsAsync = ref.watch(pqrsProvider);
    final filter = ref.watch(pqrsStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PQRS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.read(pqrsProvider.notifier).refresh(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _FilterBar(current: filter),
        ),
      ),
      body: AsyncValueWidget<List<PqrsItem>>(
        value: pqrsAsync,
        data: (items) {
          final filtered = _applyFilter(items, filter);
          return RefreshIndicator(
            onRefresh: () => ref.read(pqrsProvider.notifier).refresh(),
            child: filtered.isEmpty
                ? _EmptyState(filter: filter)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _PqrsCard(item: filtered[i]),
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewPqrsSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva PQRS'),
      ),
    );
  }

  List<PqrsItem> _applyFilter(List<PqrsItem> items, String filter) {
    if (filter == 'all') return items;
    return items.where((p) => p.status == filter).toList();
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.current});
  final String current;

  static const _filters = [
    ('all', 'Todas'),
    ('pending', 'Pendiente'),
    ('in_progress', 'En trámite'),
    ('responded', 'Respondida'),
    ('closed', 'Cerrada'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: _filters.map((f) {
          final (value, label) = f;
          final selected = current == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  ref.read(pqrsStatusFilterProvider.notifier).state = value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primary
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── PQRS card ────────────────────────────────────────────────────────────────

class _PqrsCard extends StatelessWidget {
  const _PqrsCard({required this.item});
  final PqrsItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd/MM/yyyy', 'es');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context, item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────
              Row(
                children: [
                  _TypeBadge(type: item.type, label: item.typeLabel),
                  const SizedBox(width: 6),
                  if (item.isAnswered)
                    const Icon(Icons.mark_email_read_outlined,
                        size: 14, color: Colors.green),
                  const Spacer(),
                  _StatusBadge(status: item.status, label: item.statusLabel),
                ],
              ),
              const SizedBox(height: 8),

              // ── Radicado ─────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.tag_outlined,
                      size: 12, color: cs.outlineVariant),
                  const SizedBox(width: 4),
                  Text(
                    item.radicadoNumber,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: cs.outlineVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── Subject ──────────────────────────────────────────
              Text(
                item.subject,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    height: 1.4),
              ),
              const SizedBox(height: 10),

              // ── Footer row ───────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 12, color: cs.outlineVariant),
                  const SizedBox(width: 4),
                  Text(
                    _fmtDate(item.createdAt, dateFmt),
                    style: TextStyle(
                        fontSize: 11, color: cs.outlineVariant),
                  ),
                  if (item.dueDate != null) ...[
                    const SizedBox(width: 10),
                    Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: item.isDueOverdue
                          ? Colors.red
                          : cs.outlineVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Plazo: ${_fmtDate(item.dueDate!, dateFmt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: item.isDueOverdue
                            ? Colors.red
                            : cs.outlineVariant,
                        fontWeight: item.isDueOverdue
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      size: 16, color: cs.outlineVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDate(String iso, DateFormat fmt) {
    try {
      return fmt.format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}

// ─── Badges ───────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.label});
  final String type;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'complaint' => Colors.red,
      'claim' => Colors.orange,
      'suggestion' => Colors.teal,
      _ => Colors.blue, // petition
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
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});
  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      'pending' => (Colors.grey, Icons.hourglass_empty_outlined),
      'in_progress' => (Colors.blue, Icons.sync_outlined),
      'responded' => (Colors.green, Icons.check_circle_outline),
      'closed' => (Colors.purple, Icons.lock_outline),
      _ => (Colors.grey, Icons.circle_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(80)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Detail bottom sheet ──────────────────────────────────────────────────────

void _showDetail(BuildContext context, PqrsItem item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => _DetailSheetContent(
        item: item,
        scrollController: ctrl,
      ),
    ),
  );
}

class _DetailSheetContent extends StatelessWidget {
  const _DetailSheetContent({
    required this.item,
    required this.scrollController,
  });

  final PqrsItem item;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final longFmt = DateFormat("dd 'de' MMMM 'de' yyyy", 'es');
    final shortFmt = DateFormat('dd/MM/yyyy', 'es');

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        // Handle
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // ── Radicado hero ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  color: cs.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Radicado',
                        style: TextStyle(
                            fontSize: 11, color: cs.onPrimaryContainer)),
                    Text(
                      item.radicadoNumber,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: cs.onPrimaryContainer,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy_outlined,
                    color: cs.onPrimaryContainer, size: 18),
                tooltip: 'Copiar',
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: item.radicadoNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Radicado copiado'),
                        duration: Duration(seconds: 1)),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Badges row ───────────────────────────────────────────
        Row(
          children: [
            _TypeBadge(type: item.type, label: item.typeLabel),
            const SizedBox(width: 8),
            _StatusBadge(status: item.status, label: item.statusLabel),
          ],
        ),
        const SizedBox(height: 14),

        // ── Subject ──────────────────────────────────────────────
        Text(item.subject,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        // ── Timeline ─────────────────────────────────────────────
        _Timeline(item: item, shortFmt: shortFmt),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),

        // ── Description ──────────────────────────────────────────
        Text('Descripción',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text(item.description,
            style: const TextStyle(fontSize: 14, height: 1.6)),

        // ── Admin response ───────────────────────────────────────
        if (item.response != null && item.response!.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.forum_outlined,
                  size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Text('Respuesta de la administración',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: Colors.green)),
            ],
          ),
          if (item.respondedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              _fmtLong(item.respondedAt!, longFmt),
              style:
                  TextStyle(fontSize: 11, color: cs.outlineVariant),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(15),
              border: Border.all(color: Colors.green.withAlpha(60)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(item.response!,
                style: const TextStyle(fontSize: 14, height: 1.6)),
          ),
        ],
      ],
    );
  }

  static String _fmtLong(String iso, DateFormat fmt) {
    try {
      return fmt.format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.item, required this.shortFmt});

  final PqrsItem item;
  final DateFormat shortFmt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = <({String label, String? date, bool done, bool active})>[
      (
        label: 'Radicada',
        date: _fmt(item.createdAt),
        done: true,
        active: false,
      ),
      (
        label: 'En trámite',
        date: item.status == 'in_progress' || item.isAnswered
            ? 'Asignada'
            : null,
        done: item.status == 'in_progress' || item.isAnswered,
        active: item.status == 'in_progress',
      ),
      (
        label: 'Respondida',
        date: _fmt(item.respondedAt),
        done: item.isAnswered,
        active: item.status == 'responded',
      ),
      (
        label: 'Cerrada',
        date: _fmt(item.closedAt),
        done: item.status == 'closed',
        active: item.status == 'closed',
      ),
    ];

    return Row(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final step = e.value;
        final isLast = i == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.done
                            ? (step.active ? cs.primary : Colors.green)
                            : cs.surfaceContainerHighest,
                        border: step.active
                            ? Border.all(color: cs.primary, width: 2)
                            : null,
                      ),
                      child: Icon(
                        step.done
                            ? Icons.check
                            : Icons.circle_outlined,
                        size: 14,
                        color: step.done
                            ? Colors.white
                            : cs.outlineVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: step.active
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: step.done
                            ? cs.onSurface
                            : cs.outlineVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (step.date != null)
                      Text(
                        step.date!,
                        style: TextStyle(
                            fontSize: 8, color: cs.outlineVariant),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 28),
                    color: step.done
                        ? Colors.green
                        : cs.outlineVariant.withAlpha(60),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String? _fmt(String? iso) {
    if (iso == null) return null;
    try {
      return shortFmt.format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return null;
    }
  }
}

// ─── New PQRS bottom sheet ────────────────────────────────────────────────────

void _showNewPqrsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _NewPqrsSheet(),
  );
}

class _NewPqrsSheet extends ConsumerStatefulWidget {
  const _NewPqrsSheet();

  @override
  ConsumerState<_NewPqrsSheet> createState() => _NewPqrsSheetState();
}

class _NewPqrsSheetState extends ConsumerState<_NewPqrsSheet> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'petition';
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  static const _types = [
    ('petition', 'Petición', Icons.inbox_outlined),
    ('complaint', 'Queja', Icons.thumb_down_outlined),
    ('claim', 'Reclamo', Icons.gavel_outlined),
    ('suggestion', 'Sugerencia', Icons.lightbulb_outlined),
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(pqrsProvider.notifier).create({
        'type': _type,
        'subject': _subjectCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
      });
      if (mounted) {
        _subjectCtrl.clear();
        _descCtrl.clear();
        setState(() => _type = 'petition');
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PQRS radicada exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo radicar la PQRS.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Nueva PQRS',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // ── Type selector ────────────────────────────────────
            Text('Tipo',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _types.map((t) {
                final (value, label, icon) = t;
                final selected = _type == value;
                return FilterChip(
                  label: Text(label),
                  avatar: Icon(icon, size: 14),
                  selected: selected,
                  onSelected: (_) => setState(() => _type = value),
                  selectedColor: cs.primaryContainer,
                  checkmarkColor: cs.onPrimaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Subject ──────────────────────────────────────────
            TextFormField(
              controller: _subjectCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Asunto *',
                hintText: 'Resumen breve de la solicitud',
                prefixIcon: Icon(Icons.subject_outlined),
                counterText: '',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'El asunto es requerido' : null,
            ),
            const SizedBox(height: 12),

            // ── Description ──────────────────────────────────────
            TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 5,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Descripción *',
                hintText: 'Describe detalladamente tu solicitud…',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.notes_outlined),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().length < 10
                      ? 'Mínimo 10 caracteres'
                      : null,
            ),
            const SizedBox(height: 20),

            // ── Submit ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined),
                label: Text(
                    _submitting ? 'Radicando…' : 'Radicar PQRS'),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Recibirá respuesta dentro de 15 días hábiles.',
                style:
                    TextStyle(fontSize: 11, color: cs.outlineVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final String filter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFiltered = filter != 'all';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered ? Icons.filter_list_off_outlined : Icons.forum_outlined,
              size: 72,
              color: cs.outlineVariant,
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered
                  ? 'Sin PQRS en este estado'
                  : 'No has radicado solicitudes',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Prueba con otro filtro.'
                  : 'Usa el botón + para radicar una petición,\nqueja, reclamo o sugerencia.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.outlineVariant,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
