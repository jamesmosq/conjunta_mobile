import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final greeting = _greeting();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              user?.name.isNotEmpty == true ? user!.name.split(' ').first : 'Residente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
            tooltip: 'Notificaciones',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(authStateProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner de bienvenida
            _WelcomeBanner(user: user),
            const SizedBox(height: 20),

            // Acceso rápido
            Text(
              'Acceso rápido',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            _QuickAccessGrid(),
            const SizedBox(height: 20),

            // Módulos
            Text(
              'Servicios',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            _ServicesList(),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.primary, color.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conjunto Residencial',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bienvenido a tu app',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (user?.apartmentId != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Apto ${user?.apartmentId}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.home_work_rounded, size: 56, color: Colors.white30),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      _QuickItem(Icons.door_front_door_outlined, 'Pre-Auth', '/porteria'),
      _QuickItem(Icons.local_shipping_outlined, 'Paquetes', '/porteria'),
      _QuickItem(Icons.build_outlined, 'Reporte', '/maintenance/new'),
      _QuickItem(Icons.campaign_outlined, 'Avisos', '/announcements'),
    ];

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: GestureDetector(
                onTap: () => context.push(item.route),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Icon(item.icon,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28),
                        const SizedBox(height: 6),
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickItem {
  const _QuickItem(this.icon, this.label, this.route);
  final IconData icon;
  final String label;
  final String route;
}

class _ServicesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceItem(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Estado de cuenta',
        subtitle: 'Cuotas, pagos y paz y salvo',
        route: '/account',
        color: const Color(0xFF4CAF50),
      ),
      _ServiceItem(
        icon: Icons.door_front_door_outlined,
        title: 'Portería',
        subtitle: 'Visitas, pre-autorizaciones y paquetes',
        route: '/porteria',
        color: const Color(0xFF2196F3),
      ),
      _ServiceItem(
        icon: Icons.event_available_outlined,
        title: 'Áreas comunes',
        subtitle: 'Reserva salones, canchas y más',
        route: '/areas',
        color: const Color(0xFF9C27B0),
      ),
      _ServiceItem(
        icon: Icons.build_circle_outlined,
        title: 'Reportes de daños',
        subtitle: 'Solicitudes de mantenimiento',
        route: '/maintenance',
        color: const Color(0xFFFF9800),
      ),
      _ServiceItem(
        icon: Icons.campaign_outlined,
        title: 'Comunicados',
        subtitle: 'Avisos y noticias del conjunto',
        route: '/announcements',
        color: const Color(0xFF1565C0),
      ),
      _ServiceItem(
        icon: Icons.forum_outlined,
        title: 'PQRS',
        subtitle: 'Peticiones, quejas y reclamos',
        route: '/pqrs',
        color: const Color(0xFFE91E63),
      ),
    ];

    return Column(
      children: services
          .map(
            (s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(s.icon, color: s.color, size: 24),
                ),
                title: Text(s.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(s.subtitle,
                    style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_outlined),
                onTap: () => context.push(s.route),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;
}
