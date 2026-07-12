import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/apartment_lookup.dart';
import '../../../../core/widgets/apartment_picker.dart';
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
            if (isPortero) const _QuickAccessRow(),
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

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _QuickAccessChip(
              icon: Icons.login,
              label: 'Registrar entrada',
              onTap: () => context.push('/visits/new'),
            ),
            const SizedBox(width: 8),
            _QuickAccessChip(
              icon: Icons.report_outlined,
              label: 'Incidente',
              onTap: () => context.push('/shift-incidents/new'),
            ),
            const SizedBox(width: 8),
            _QuickAccessChip(
              icon: Icons.local_parking_outlined,
              label: 'Parqueaderos',
              onTap: () => context.push('/parking'),
            ),
            const SizedBox(width: 8),
            _QuickAccessChip(
              icon: Icons.block_outlined,
              label: 'No autorizados',
              onTap: () => context.push('/blacklist'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessChip extends StatelessWidget {
  const _QuickAccessChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
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

class _VisitCard extends ConsumerWidget {
  const _VisitCard({required this.visit});
  final Visit visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es');
    final isPortero = ref.watch(authStateProvider).value?.isPortero ?? false;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
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
          if (isPortero && visit.isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmExit(context, ref),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Marcar salida'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar salida'),
        content: Text('¿Confirmas la salida de ${visit.visitorName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(visitsProvider.notifier).markExit(visit.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Salida registrada — ${visit.visitorName}.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo registrar la salida.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ── Pre-Auth Tab ─────────────────────────────────────────────────────────────

class _PreAuthTab extends ConsumerWidget {
  const _PreAuthTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preAuthAsync = ref.watch(preAuthorizationsProvider);
    // Crear pre-autorizaciones es solo de copropietario/administrador
    // (ver StorePreAuthRequest::authorize) — el portero solo puede consultarlas.
    final isPortero = ref.watch(authStateProvider).value?.isPortero ?? false;
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
      floatingActionButton: isPortero
          ? null
          : FloatingActionButton.extended(
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
    final isPortero = ref.watch(authStateProvider).value?.isPortero ?? false;
    return Scaffold(
      body: AsyncValueWidget<List<Package>>(
        value: packagesAsync,
        data: (packages) => RefreshIndicator(
          onRefresh: () => ref.read(packagesProvider.notifier).refresh(),
          child: packages.isEmpty
              ? _emptyState('No hay paquetes registrados', Icons.inventory_2_outlined)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: packages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _PackageCard(package: packages[i]),
                ),
        ),
      ),
      floatingActionButton: isPortero
          ? FloatingActionButton.extended(
              onPressed: () => _showRegisterPackageSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo'),
            )
          : null,
    );
  }

  Future<void> _showRegisterPackageSheet(
      BuildContext context, WidgetRef ref) async {
    final descriptionController = TextEditingController();
    final senderController = TextEditingController();
    ApartmentLookup? apartment;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registrar paquete',
                    style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 16),
                ApartmentPicker(
                  onSelected: (apt) => setSheetState(() => apartment = apt),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción *',
                    hintText: 'Caja mediana, sobre, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: senderController,
                  decoration: const InputDecoration(
                    labelText: 'Remitente (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (apartment == null ||
                          descriptionController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Selecciona el apartamento e ingresa la descripción.')),
                        );
                        return;
                      }
                      try {
                        await ref.read(packagesProvider.notifier).create(
                              apartmentId: apartment!.id,
                              description: descriptionController.text.trim(),
                              sender: senderController.text.trim(),
                            );
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (_) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('No se pudo registrar el paquete.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Registrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paquete registrado correctamente.')),
      );
    }
  }
}

class _PackageCard extends ConsumerWidget {
  const _PackageCard({required this.package});
  final Package package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es');
    final isPortero = ref.watch(authStateProvider).value?.isPortero ?? false;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
            title: Text(package.description ?? 'Paquete #${package.id}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              package.isPending
                  ? (package.arrivedAt.isNotEmpty
                      ? 'Llegó: ${fmt.format(DateTime.parse(package.arrivedAt))}'
                      : 'Paquete pendiente de entrega')
                  : 'Entregado a ${package.deliveredToName ?? '—'}'
                      '${package.deliveredAt != null ? ' · ${fmt.format(DateTime.parse(package.deliveredAt!))}' : ''}',
            ),
            trailing: package.isPending
                ? const StatusChip(label: 'Pendiente', color: Colors.orange)
                : const StatusChip(label: 'Entregado', color: Colors.green),
          ),
          if (isPortero && package.isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => _showDeliverSheet(context, ref),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Entregar'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDeliverSheet(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final deliveredTo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entregar paquete'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Entregado a',
            hintText: 'Nombre de quien lo recibe',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx, name);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (deliveredTo == null || deliveredTo.isEmpty) return;
    if (!context.mounted) return;

    try {
      await ref.read(packagesProvider.notifier).deliver(package.id, deliveredTo);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paquete entregado a $deliveredTo.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo registrar la entrega. Intenta de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
