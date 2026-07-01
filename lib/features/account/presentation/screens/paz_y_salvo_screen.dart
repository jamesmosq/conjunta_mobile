import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../data/account_repository.dart';
import '../../models/account_statement.dart';
import '../../models/charge.dart';
import '../../providers/account_provider.dart';

class PazYSalvoScreen extends ConsumerWidget {
  const PazYSalvoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statementAsync = ref.watch(accountStatementProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paz y Salvo')),
      body: AsyncValueWidget(
        value: statementAsync,
        data: (statement) {
          if (statement == null) {
            return const Center(child: Text('No tienes apartamento asignado.'));
          }
          return _Body(statement: statement);
        },
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.statement});

  final AccountStatement statement;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _downloadingCert = false;
  bool _downloadingStatement = false;
  DateTime? _certGeneratedAt;
  DateTime? _statementGeneratedAt;

  final _moneyFmt = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  AccountStatement get statement => widget.statement;

  Future<void> _downloadPazYSalvo() async {
    setState(() => _downloadingCert = true);
    try {
      final bytes = await ref
          .read(accountRepositoryProvider)
          .downloadPazYSalvo(statement.apartmentId);
      await _openPdf(bytes, 'paz_y_salvo_${statement.apartmentId}');
      setState(() => _certGeneratedAt = DateTime.now());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar el certificado.')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingCert = false);
    }
  }

  Future<void> _downloadStatement() async {
    setState(() => _downloadingStatement = true);
    try {
      final bytes = await ref
          .read(accountRepositoryProvider)
          .downloadStatement(statement.apartmentId);
      await _openPdf(bytes, 'estado_cuenta_${statement.apartmentId}');
      setState(() => _statementGeneratedAt = DateTime.now());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar el estado de cuenta.')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingStatement = false);
    }
  }

  Future<void> _openPdf(List<int> bytes, String name) async {
    final tmpDir = Directory.systemTemp;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tmpDir.path}/${name}_$ts.pdf');
    await file.writeAsBytes(bytes);
    await OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final pendingCharges =
        statement.charges.where((c) => !c.isPaid).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // ── Status hero ─────────────────────────────────────────────────
        _StatusHero(
          pazYSalvo: statement.pazYSalvo,
          balanceDue: statement.balanceDue,
          moneyFmt: _moneyFmt,
        ),
        const SizedBox(height: 24),

        // ── Paz y salvo certificate ──────────────────────────────────────
        _DocumentCard(
          icon: Icons.verified_outlined,
          title: 'Certificado de Paz y Salvo',
          subtitle: statement.pazYSalvo
              ? 'Tu apartamento está al día. Puedes descargar el certificado oficial firmado digitalmente.'
              : 'El certificado no está disponible mientras existan saldos pendientes.',
          available: statement.pazYSalvo,
          generatedAt: _certGeneratedAt,
          isDownloading: _downloadingCert,
          onDownload: statement.pazYSalvo ? _downloadPazYSalvo : null,
          legalNote: 'Válido según Art. 7 Ley 527/1999 — firma digital.',
        ),
        const SizedBox(height: 12),

        // ── Estado de cuenta PDF ─────────────────────────────────────────
        _DocumentCard(
          icon: Icons.description_outlined,
          title: 'Estado de Cuenta',
          subtitle: 'Resumen detallado de todos los cargos, pagos y saldos del apartamento.',
          available: true,
          generatedAt: _statementGeneratedAt,
          isDownloading: _downloadingStatement,
          onDownload: _downloadStatement,
        ),

        // ── Pending charges (when in debt) ───────────────────────────────
        if (!statement.pazYSalvo && pendingCharges.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Cargos pendientes',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...pendingCharges.map(
            (c) => _PendingChargeRow(charge: c, moneyFmt: _moneyFmt),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total a pagar',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  _moneyFmt.format(statement.balanceDue),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PaymentInfoBanner(),
        ],
      ],
    );
  }
}

// ─── Status hero ──────────────────────────────────────────────────────────────

class _StatusHero extends StatelessWidget {
  const _StatusHero({
    required this.pazYSalvo,
    required this.balanceDue,
    required this.moneyFmt,
  });

  final bool pazYSalvo;
  final double balanceDue;
  final NumberFormat moneyFmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: pazYSalvo
              ? [const Color(0xFF1B5E20), const Color(0xFF388E3C)]
              : [const Color(0xFFB71C1C), const Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(
              pazYSalvo ? Icons.verified : Icons.gpp_bad_outlined,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            pazYSalvo ? '¡Apartamento al día!' : 'Saldo pendiente',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pazYSalvo
                ? 'No tienes obligaciones financieras pendientes.'
                : moneyFmt.format(balanceDue),
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: pazYSalvo ? 14 : 28,
              fontWeight:
                  pazYSalvo ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Document card ────────────────────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.available,
    required this.isDownloading,
    this.onDownload,
    this.generatedAt,
    this.legalNote,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool available;
  final bool isDownloading;
  final VoidCallback? onDownload;
  final DateTime? generatedAt;
  final String? legalNote;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeFmt = DateFormat('dd/MM/yyyy HH:mm', 'es');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: available
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: available
                        ? cs.onPrimaryContainer
                        : cs.outlineVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (generatedAt != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Generado ${timeFmt.format(generatedAt!)}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.4),
            ),
            if (legalNote != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 12, color: cs.outlineVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      legalNote!,
                      style: TextStyle(
                          fontSize: 11, color: cs.outlineVariant),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    (available && !isDownloading) ? onDownload : null,
                icon: isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(available
                        ? Icons.download_outlined
                        : Icons.lock_outlined),
                label: Text(
                  isDownloading
                      ? 'Generando PDF…'
                      : available
                          ? 'Descargar PDF'
                          : 'No disponible',
                ),
                style: available
                    ? null
                    : FilledButton.styleFrom(
                        backgroundColor: cs.surfaceContainerHighest,
                        foregroundColor: cs.outlineVariant,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pending charge row ───────────────────────────────────────────────────────

class _PendingChargeRow extends StatelessWidget {
  const _PendingChargeRow({required this.charge, required this.moneyFmt});

  final Charge charge;
  final NumberFormat moneyFmt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: charge.isOverdue
            ? Colors.red.withAlpha(15)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: charge.isOverdue
            ? Border.all(color: Colors.red.withAlpha(60))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  charge.description,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (charge.periodLabel != null)
                  Text(
                    charge.periodLabel!,
                    style: TextStyle(
                        fontSize: 11, color: cs.outlineVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                moneyFmt.format(charge.balanceDue),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.red,
                ),
              ),
              if (charge.isOverdue)
                const Text(
                  'Vencido',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Payment info banner ──────────────────────────────────────────────────────

class _PaymentInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.payments_outlined,
              color: cs.onSecondaryContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Para cancelar los saldos pendientes, comunícate con la administración o realiza el pago en las instalaciones del conjunto.',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSecondaryContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
