import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/profile/models/resident_profile.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

// Account
import '../../features/account/presentation/screens/account_screen.dart';
import '../../features/account/presentation/screens/paz_y_salvo_screen.dart';

// Portería
import '../../features/porteria/presentation/screens/porteria_screen.dart';
import '../../features/porteria/presentation/screens/pre_auth_screen.dart';
import '../../features/porteria/presentation/screens/new_pre_auth_screen.dart';
import '../../features/porteria/presentation/screens/visit_history_screen.dart';

// Áreas comunes
import '../../features/areas/models/common_area.dart';
import '../../features/areas/presentation/screens/areas_screen.dart';
import '../../features/areas/presentation/screens/area_detail_screen.dart';
import '../../features/areas/presentation/screens/book_area_screen.dart';

// Mantenimiento
import '../../features/maintenance/presentation/screens/maintenance_screen.dart';
import '../../features/maintenance/presentation/screens/new_report_screen.dart';
import '../../features/maintenance/presentation/screens/report_detail_screen.dart';
import '../../features/maintenance/models/maintenance_request.dart';

// Notificaciones
import '../../features/notifications/presentation/screens/notifications_screen.dart';

// Comunicados
import '../../features/announcements/presentation/screens/announcements_screen.dart';

// PQRS
import '../../features/pqrs/presentation/screens/pqrs_screen.dart';

// Perfil
import '../../features/profile/presentation/screens/profile_screen.dart';

// Contratista
import '../../features/contractor/presentation/screens/work_orders_screen.dart';
import '../../features/contractor/presentation/screens/work_order_detail_screen.dart';
import '../../features/contractor/models/work_order.dart';

// Encuestas (RF-ENC)
import '../../features/surveys/presentation/screens/surveys_screen.dart';
import '../../features/surveys/presentation/screens/survey_answer_screen.dart';

// Chat (RF-CHT)
import '../../features/chat/presentation/screens/conversations_screen.dart';
import '../../features/chat/presentation/screens/chat_thread_screen.dart';

// QR Invitaciones (RF-QRI)
import '../../features/qr_invitation/models/visit_qr_code.dart';
import '../../features/qr_invitation/presentation/screens/qr_history_screen.dart';
import '../../features/qr_invitation/presentation/screens/new_qr_screen.dart';
import '../../features/qr_invitation/presentation/screens/qr_detail_screen.dart';

// Rondas (RF-MRD)
import '../../features/patrol/presentation/screens/patrol_screen.dart';
import '../../features/patrol/presentation/screens/active_patrol_screen.dart';
import '../../features/patrol/presentation/screens/qr_scan_screen.dart';
import '../../features/patrol/presentation/screens/patrol_incident_form.dart';

// Validar acceso (RF-QRI) — portero
import '../../features/access_validation/presentation/screens/validate_access_screen.dart';

import '../config/app_config.dart';
import '../widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: AppConfig.navigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final user = authState.value;
      final isAuthenticated = user != null;
      final loc = state.matchedLocation;
      final isPublic = loc == '/login' || loc == '/forgot-password';

      if (!isAuthenticated && !isPublic) return '/login';
      if (isAuthenticated && isPublic) {
        if (user.isContratista) return '/contractor/orders';
        if (user.isPortero) return '/porteria-home';
        return '/home';
      }
      return null;
    },
    refreshListenable: _AuthStateListenable(ref),
    routes: [
      // ── Auth público ──────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // ── Shell copropietario (bottom nav 5 tabs) ────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => CopropietarioShell(navigationShell: shell),
        branches: [
          // 0: Inicio
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => const HomeScreen(),
            ),
          ]),
          // 1: Cuenta
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/account',
              builder: (_, __) => const AccountScreen(),
            ),
          ]),
          // 2: Portería
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/porteria',
              builder: (_, __) => const PorteriaScreen(),
            ),
          ]),
          // 3: Reservas
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/areas',
              builder: (_, __) => const AreasScreen(),
            ),
          ]),
          // 4: Más → Perfil
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/more',
              builder: (_, __) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      // ── Rutas push sobre el shell ──────────────────────────────────────
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/account/paz-y-salvo',
        builder: (_, __) => const PazYSalvoScreen(),
      ),
      GoRoute(
        path: '/announcements',
        builder: (_, __) => const AnnouncementsScreen(),
      ),
      GoRoute(
        path: '/pqrs',
        builder: (_, __) => const PqrsScreen(),
      ),
      GoRoute(
        path: '/visits/pre-auth',
        builder: (_, __) => const PreAuthScreen(),
      ),
      GoRoute(
        path: '/visits/history',
        builder: (_, __) => const VisitHistoryScreen(),
      ),
      GoRoute(
        path: '/porteria/pre-auth/new',
        builder: (_, __) => const NewPreAuthScreen(),
      ),
      // Área: detalle con disponibilidad
      GoRoute(
        path: '/areas/:id',
        builder: (context, state) {
          final areaId = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final area = state.extra as CommonArea?;
          return AreaDetailScreen(areaId: areaId, area: area);
        },
      ),
      // Área: formulario de reserva — areaId en la ruta
      GoRoute(
        path: '/areas/:id/book',
        builder: (context, state) {
          final areaId = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return BookAreaScreen(areaId: areaId);
        },
      ),
      GoRoute(
        path: '/maintenance',
        builder: (_, __) => const MaintenanceScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const NewReportScreen(),
          ),
          GoRoute(
            path: 'detail',
            builder: (context, state) {
              final request = state.extra as MaintenanceRequest?;
              return ReportDetailScreen(request: request);
            },
          ),
        ],
      ),
      // Encuestas (RF-ENC)
      GoRoute(
        path: '/surveys',
        builder: (_, __) => const SurveysScreen(),
      ),
      GoRoute(
        path: '/surveys/:id',
        builder: (context, state) {
          final surveyId =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return SurveyAnswerScreen(surveyId: surveyId);
        },
      ),

      // QR Invitaciones (RF-QRI) — copropietario
      GoRoute(
        path: '/qr-invitations',
        builder: (_, __) => const QrHistoryScreen(),
      ),
      GoRoute(
        path: '/qr-invitations/new',
        builder: (_, __) => const NewQrScreen(),
      ),
      GoRoute(
        path: '/qr-invitations/:id',
        builder: (context, state) {
          final qr = state.extra as VisitQrCode?;
          if (qr == null) return const QrHistoryScreen();
          return QrDetailScreen(qr: qr);
        },
      ),

      // Chat (RF-CHT) — copropietario ↔ administración
      GoRoute(
        path: '/chat',
        builder: (_, __) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final conversationId =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final extra = state.extra as Map<String, dynamic>?;
          final contraparteName =
              extra?['name'] as String? ?? 'Administrador';
          return ChatThreadScreen(
            conversationId: conversationId,
            contraparteName: contraparteName,
          );
        },
      ),

      // Rondas (RF-MRD) — portero
      GoRoute(
        path: '/patrol',
        builder: (_, __) => const PatrolScreen(),
      ),
      GoRoute(
        path: '/patrol/active/:sessionId',
        builder: (context, state) {
          final sessionId =
              int.tryParse(state.pathParameters['sessionId'] ?? '') ?? 0;
          return ActivePatrolScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/patrol/scan/:sessionId',
        builder: (context, state) {
          final sessionId =
              int.tryParse(state.pathParameters['sessionId'] ?? '') ?? 0;
          return QrScanScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/patrol/incident/:sessionId',
        builder: (context, state) {
          final sessionId =
              int.tryParse(state.pathParameters['sessionId'] ?? '') ?? 0;
          final checkpointId = state.extra as int?;
          return PatrolIncidentForm(
            sessionId: sessionId,
            checkpointId: checkpointId,
          );
        },
      ),

      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) {
          final profile = state.extra as ResidentProfile?;
          if (profile == null) return const ProfileScreen();
          return EditProfileScreen(profile: profile);
        },
      ),

      // ── Shell portero (bottom nav 3 tabs) ─────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => PorteroShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/porteria-home',
              builder: (_, __) => const PorteriaScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/access-validation',
              builder: (_, __) => const ValidateAccessScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/porteria-profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      // ── Shell contratista (bottom nav 2 tabs) ─────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ContratistaShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/contractor/orders',
              builder: (_, __) => const WorkOrdersScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/contractor/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/contractor/orders/detail',
        builder: (context, state) {
          final order = state.extra as WorkOrder?;
          return WorkOrderDetailScreen(workOrder: order);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
});

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
