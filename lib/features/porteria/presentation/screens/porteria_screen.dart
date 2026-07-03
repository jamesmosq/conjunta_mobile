import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/package.dart';
import '../../models/pre_authorization.dart';
import '../../models/visit.dart';
import '../../providers/porteria_provider.dart';

class PorteriaScreen extends ConsumerWidget {
  const PorteriaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isPortero = user?.isPortero ?? false;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Portería'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Visitas', icon: Icon(Icons.people_outline)),
              Tab(text: 'Pre-Autorizaciones', icon: Icon(Icons.verified_user_outlined)),
              Tab(text: 'Paquetes', icon: Icon(Icons.inventory_2_outlined)),
            ],
          ),
        ),
        body: Column(
          children: [
            if (isPortero) const _RondasBanner(),
            const Expanded(
              child: TabBarView(
                children: [
                  _VisitsTab(),
                  _PreAuthTab(),
                  _PackagesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RondasBanner extends StatelessWidget {
  const _RondasBanner();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/patrol'),
      child: Container(
        width: double.infinity,
        color: Colors.indigo.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: const Row(
          children: [
            Icon(Icons.security, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rondas de Vigilancia',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

// ── Visitas Tab ──────────────────────────────────────────────────────────────

class _VisitsTab extends ConsumerWidget {
  const _VisitsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(visitsProvider);
    return AsyncValueWidget<List<Visit>>(
      value: visitsAsync,
      data: (visits) => RefreshIndicator(
        onRefresh: () => ref.read(visitsProvider.notifier).refresh(),
        child: visits.isEmpty
            ? _emptyState('No hay visitas registradas', Icons.people_outline)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: visits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _VisitCard(visit: visits[i]),
              ),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit});
  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es');
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(visit.visitorName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: visit.entryAt != null
            ? Text('Entrada: ${fmt.format(DateTime.parse(visit.entryAt!))}')
            : null,
        trailing: visit.isActive
            ? const StatusChip(label: 'Activa', color: Colors.green)
            : const StatusChip(label: 'Salió', color: Colors.grey),
      ),
    );
  }
}

// ── Pre-Auth Tab ─────────────────────────────────────────────────────────────

class _PreAuthTab extends ConsumerWidget {
  const _PreAuthTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preAuthAsync = ref.watch(preAuthorizationsProvider);
    return Scaffold(
      body: AsyncValueWidget<List<PreAuthorization>>(
        value: preAuthAsync,
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.read(preAuthorizationsProvider.notifier).refresh(),
          child: list.isEmpty
              ? _emptyState(
                  'No tienes pre-autorizaciones activas', Icons.verified_user_outlined)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _PreAuthCard(auth: list[i]),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/porteria/pre-auth/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }
}

class _PreAuthCard extends ConsumerWidget {
  const _PreAuthCard({required this.auth});
  final PreAuthorization auth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yyyy', 'es');
    final subtitle = _buildSubtitle(fmt);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            auth.isVehicle
                ? Icons.directions_car_outlined
                : Icons.verified_user_outlined,
          ),
        ),
        title: Text(auth.visitorName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Eliminar pre-autorización'),
                content: Text('¿Deseas eliminar la pre-autorización de ${auth.visitorName}?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Eliminar')),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await ref
                  .read(preAuthorizationsProvider.notifier)
                  .delete(auth.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pre-autorización eliminada')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  String _buildSubtitle(DateFormat fmt) {
    if (auth.isRecurring) {
      final from = auth.allowedFrom ?? '';
      final until = auth.allowedUntil ?? '';
      return auth.arrivalModeLabel +
          (from.isNotEmpty ? ' · $from – $until' : '');
    }
    if (auth.expectedAt != null) {
      try {
        final date = fmt.format(DateTime.parse(auth.expectedAt!).toLocal());
        return '${auth.arrivalModeLabel} · $date';
      } catch (_) {}
    }
    if (auth.expiresAt != null) {
      try {
        final date = fmt.format(DateTime.parse(auth.expiresAt!).toLocal());
        return '${auth.arrivalModeLabel} · vence $date';
      } catch (_) {}
    }
    return auth.arrivalModeLabel;
  }
}

// ── Packages Tab ─────────────────────────────────────────────────────────────

class _PackagesTab extends ConsumerWidget {
  const _PackagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(packagesProvider);
    return AsyncValueWidget<List<Package>>(
      value: packagesAsync,
      data: (packages) => RefreshIndicator(
        onRefresh: () => ref.read(packagesProvider.notifier).refresh(),
        child: packages.isEmpty
            ? _emptyState('No hay paquetes registrados', Icons.inventory_2_outlined)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: packages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _PackageCard(package: packages[i]),
              ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package});
  final Package package;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es');
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
        title: Text(package.description ?? 'Paquete #${package.id}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Llegó: ${fmt.format(DateTime.parse(package.arrivedAt))}'),
        trailing: package.isPending
            ? const StatusChip(label: 'Pendiente', color: Colors.orange)
            : const StatusChip(label: 'Entregado', color: Colors.green),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _emptyState(String message, IconData icon) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(message,
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center),
      ],
    ),
  );
}
