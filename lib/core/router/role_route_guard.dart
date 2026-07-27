/// Guard de rol a nivel de router — segunda línea de defensa después de que
/// las pantallas (ej. home_screen.dart) ya ocultan botones según el rol.
/// El router en sí no tenía ninguna verificación por ruta individual: nada
/// impedía llegar a una pantalla que no corresponde a un rol si algo lo
/// empuja ahí (deep link de una notificación, un context.push mal apuntado
/// en código futuro, etc.).
///
/// Rutas no listadas aquí quedan abiertas a cualquier usuario autenticado,
/// igual que antes de este guard — son pantallas genéricas o de lectura
/// compartida (home, notificaciones, comunicados, PQRS, mantenimiento,
/// encuestas, perfil, y la pestaña de portería de solo lectura).
const restrictedRoutePrefixes = <String, Set<String>>{
  '/patrol': {'portero'},
  '/access-validation': {'portero'},
  '/shift-incidents': {'portero'},
  '/parking': {'portero'},
  '/blacklist': {'portero'},
  '/visits/new': {'portero'},
  '/staff-access': {'portero'},
  '/contractor': {'contratista'},
  '/qr-invitations': {'copropietario', 'administrador'},
  '/chat': {'copropietario', 'administrador'},
  '/porteria/pre-auth/new': {'copropietario', 'administrador'},
  '/my-badge': {'administrador', 'auxiliar_contable', 'consejo', 'revisor_fiscal'},
  '/my-parking': {'copropietario'},
  '/areas': {'copropietario'},
  '/account': {'copropietario'},
};

String homeRouteForRole(String role) {
  if (role == 'contratista') return '/contractor/orders';
  if (role == 'portero') return '/porteria-home';
  return '/home';
}

/// Devuelve la ruta de redirección si [location] está restringida y [role]
/// no está autorizado; null si el acceso es válido (incluye rutas no listadas).
String? redirectForRestrictedRoute({required String role, required String location}) {
  for (final entry in restrictedRoutePrefixes.entries) {
    final matches = location == entry.key || location.startsWith('${entry.key}/');
    if (matches && !entry.value.contains(role)) {
      return homeRouteForRole(role);
    }
  }
  return null;
}
