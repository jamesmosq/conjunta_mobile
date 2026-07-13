import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/announcements/providers/announcements_provider.dart';
import '../../features/areas/providers/areas_provider.dart';
import '../../features/blacklist/providers/blacklist_provider.dart';
import '../../features/chat/providers/chat_provider.dart';
import '../../features/contractor/providers/contractor_provider.dart';
import '../../features/maintenance/providers/maintenance_provider.dart';
import '../../features/notifications/providers/notifications_provider.dart';
import '../../features/parking/providers/my_parking_provider.dart';
import '../../features/parking/providers/parking_provider.dart';
import '../../features/patrol/providers/patrol_provider.dart';
import '../../features/porteria/providers/live_access_provider.dart';
import '../../features/porteria/providers/porteria_provider.dart';
import '../../features/pqrs/providers/pqrs_provider.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/qr_invitation/providers/qr_invitation_provider.dart';
import '../../features/staff_badge/providers/staff_badge_provider.dart';
import '../../features/surveys/providers/surveys_provider.dart';

/// Todos los providers que cachean datos remotos ligados a una sesión.
///
/// Ninguno de estos se invalida automáticamente al cambiar de usuario — un
/// `AsyncNotifierProvider` normal vive mientras dure el proceso de la app,
/// no mientras dure la sesión. Sin este reset, cerrar sesión y volver a
/// entrar con OTRA cuenta (sin forzar el cierre del proceso) deja pantallas
/// mostrando datos cacheados del usuario anterior — perfil, paquetes,
/// reservas, etc. — hasta que cada pantalla decida refrescar por su cuenta.
void resetUserScopedProviders(Ref ref) {
  for (final provider in _userScopedProviders) {
    ref.invalidate(provider);
  }
}

final List<ProviderOrFamily> _userScopedProviders = [
  // accountStatementProvider NO va aquí: su build() hace
  // ref.watch(authStateProvider), así que ya se invalida solo cuando cambia
  // el estado de auth. Invalidarlo a mano desde AuthNotifier (dueño de
  // authStateProvider) es además lo que disparaba CircularDependencyError
  // en login()/logout() — Riverpod no permite que un provider invalide
  // sincrónicamente a otro que depende de él.
  announcementsProvider,
  commonAreasProvider,
  myBookingsProvider,
  blacklistProvider,
  chatConversationsProvider,
  activeWorkOrdersProvider,
  workOrderHistoryProvider,
  maintenanceRequestsProvider,
  notificationsProvider,
  myParkingProvider,
  parkingSpotsProvider,
  patrolProvider,
  liveAccessProvider,
  visitsProvider,
  preAuthorizationsProvider,
  visitHistoryProvider,
  packagesProvider,
  pqrsProvider,
  profileProvider,
  qrInvitationProvider,
  myBadgeProvider,
  surveysProvider,
];
