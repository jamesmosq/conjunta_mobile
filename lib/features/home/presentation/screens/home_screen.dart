import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/providers/auth_provider.dart';
import '../../../surveys/providers/surveys_provider.dart';
import '../../../chat/providers/chat_provider.dart';

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
        onRefresh: () async {
          ref.invalidate(authStateProvider);
          await Future.wait([
            ref.read(surveysProvider.notifier).refresh(),
            ref.read(chatConversationsProvider.notifier).refresh(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner de bienvenida
            _WelcomeBanner(user: user),
            const SizedBox(height: 12),

            // Banner de encuestas pendientes
            _PendingSurveysBanner(),
            const SizedBox(height: 8),

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

// ── Banner encuestas pendientes ────────────────────────────────────────────────

class _PendingSurveysBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingSurveysCountProvider);
    if (count == 0) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withValues(alpha: 0.10),
        border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.poll_outlined,
                size: 18, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count encuesta${count != 1 ? 's' : ''} pendiente${count != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                Text(
                  'Tu opinión es importante para el conjunto.',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4F46E5),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => context.push('/surveys'),
            child: const Text('Responder', style: TextStyle(fontSize: 12)),
          ),
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
      _QuickItem(Icons.qr_code_2_outlined, 'Invitar', '/qr-invitations/new'),
      _QuickItem(Icons.build_outlined, 'Reporte', '/maintenance/new'),
      _QuickItem(Icons.campaign_outlined, 'Avisos', '/announcements'),
      _QuickItem(Icons.local_parking_outlined, 'Parqueadero', '/my-parking'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items
            .map(
              (item) => SizedBox(
                width: 84,
                child: GestureDetector(
                  onTap: () => context.push(item.route),
                  child: Card(
                    margin: const EdgeInsets.only(right: 8),
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
      ),
    );
  }
}

class _QuickItem {
  const _QuickItem(this.icon, this.label, this.route);
  final IconData icon;
  final String label;
  final String route;
}

class _ServicesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadChat = ref.watch(unreadChatCountProvider);

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
      _ServiceItem(
        icon: Icons.poll_outlined,
        title: 'Encuestas',
        subtitle: 'Participa en las encuestas del conjunto',
        route: '/surveys',
        color: const Color(0xFF4F46E5),
      ),
      _ServiceItem(
        icon: Icons.qr_code_2_outlined,
        title: 'Invitaciones QR',
        subtitle: 'Genera QR de acceso para tus visitantes',
        route: '/qr-invitations',
        color: const Color(0xFF7B1FA2),
      ),
      _ServiceItem(
        icon: Icons.chat_bubble_outline,
        title: 'Chat con Administración',
        subtitle: 'Mensajes directos al administrador',
        route: '/chat',
        color: const Color(0xFF00897B),
        badge: unreadChat > 0 ? unreadChat : null,
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
                trailing: s.badge != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00897B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${s.badge}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_outlined),
                        ],
                      )
                    : const Icon(Icons.chevron_right_outlined),
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
    this.badge,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;
  final int? badge;
}
