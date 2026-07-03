import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/visit_qr_code.dart';
import '../../providers/qr_invitation_provider.dart';
import '../widgets/status_badge.dart';

class QrHistoryScreen extends ConsumerWidget {
  const QrHistoryScreen({super.key});

  static const _filters = [
    (null, 'Todos'),
    ('activo', 'Activo'),
    ('usado', 'Usado'),
    ('expirado', 'Expirado'),
    ('revocado', 'Revocado'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrInvitationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitaciones QR'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (value, label) = _filters[i];
                final selected = state.selectedStatus == value;
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => ref
                      .read(qrInvitationProvider.notifier)
                      .setFilter(value),
                  selectedColor: Colors.deepPurple.shade100,
                  checkmarkColor: Colors.deepPurple.shade700,
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.deepPurple.shade700
                        : Colors.grey.shade700,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? _ErrorView(
                        error: state.error!,
                        onRetry: () => ref
                            .read(qrInvitationProvider.notifier)
                            .refresh(),
                      )
                    : state.qrCodes.isEmpty
                        ? _EmptyView(filter: state.selectedStatus)
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(qrInvitationProvider.notifier)
                                .refresh(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.qrCodes.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) => _QrCard(
                                qr: state.qrCodes[i],
                                onTap: () => context.push(
                                  '/qr-invitations/${state.qrCodes[i].id}',
                                  extra: state.qrCodes[i],
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/qr-invitations/new');
        },
        icon: const Icon(Icons.qr_code_2),
        label: const Text('Nueva invitación'),
        backgroundColor: Colors.deepPurple.shade700,
      ),
    );
  }
}

// ── QR Card ───────────────────────────────────────────────────────────────────

class _QrCard extends StatelessWidget {
  const _QrCard({required this.qr, required this.onTap});

  final VisitQrCode qr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy', 'es');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusColor(qr.estado).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.qr_code,
                  color: _statusColor(qr.estado),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qr.visitante.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${qr.visitante.tipoDocumentoLabel}: ${qr.visitante.documento}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateRange(fmt, qr.validoDesde, qr.validoHasta),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(estado: qr.estado),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateRange(DateFormat fmt, String from, String until) {
    try {
      final f = fmt.format(DateTime.parse(from));
      final u = fmt.format(DateTime.parse(until));
      return '$f – $u';
    } catch (_) {
      return '';
    }
  }

  Color _statusColor(String status) => switch (status) {
        'activo' => Colors.green,
        'usado' => Colors.blue,
        'expirado' => Colors.orange,
        'revocado' => Colors.red,
        _ => Colors.grey,
      };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.filter});

  final String? filter;

  @override
  Widget build(BuildContext context) {
    final label = filter != null ? 'invitaciones $filter' : 'invitaciones QR';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No hay $label',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para generar una nueva.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
