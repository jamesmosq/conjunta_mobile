import 'package:flutter_test/flutter_test.dart';

import 'package:cojunta_mobile/core/router/role_route_guard.dart';

void main() {
  group('redirectForRestrictedRoute', () {
    test('permite el acceso cuando el rol está autorizado', () {
      expect(
        redirectForRestrictedRoute(role: 'portero', location: '/patrol'),
        isNull,
      );
    });

    test('redirige al home del rol cuando no está autorizado', () {
      expect(
        redirectForRestrictedRoute(role: 'copropietario', location: '/patrol'),
        '/home',
      );
      expect(
        redirectForRestrictedRoute(role: 'copropietario', location: '/contractor/orders'),
        '/home',
      );
    });

    test('las rutas no listadas siempre son null (sin restricción)', () {
      expect(
        redirectForRestrictedRoute(role: 'contratista', location: '/home'),
        isNull,
      );
      expect(
        redirectForRestrictedRoute(role: 'portero', location: '/maintenance'),
        isNull,
      );
    });

    test('coincide por prefijo de ruta, no solo exacto', () {
      expect(
        redirectForRestrictedRoute(role: 'copropietario', location: '/patrol/active/123'),
        '/home',
      );
      expect(
        redirectForRestrictedRoute(role: 'portero', location: '/patrol/scan/123'),
        isNull,
      );
    });

    test('no confunde /visits/new (solo portero) con /visits/pre-auth (compartida)', () {
      expect(
        redirectForRestrictedRoute(role: 'copropietario', location: '/visits/new'),
        '/home',
      );
      expect(
        redirectForRestrictedRoute(role: 'copropietario', location: '/visits/pre-auth'),
        isNull,
      );
    });

    test('qr-invitations y chat permiten copropietario y administrador, no a otros roles de staff', () {
      expect(
        redirectForRestrictedRoute(role: 'administrador', location: '/qr-invitations'),
        isNull,
      );
      expect(
        redirectForRestrictedRoute(role: 'consejo', location: '/chat'),
        '/home',
      );
    });

    test('areas permite copropietario y portero, no a contratista', () {
      expect(
        redirectForRestrictedRoute(role: 'copropietario', location: '/areas'),
        isNull,
      );
      expect(
        redirectForRestrictedRoute(role: 'portero', location: '/areas/5'),
        isNull,
      );
      expect(
        redirectForRestrictedRoute(role: 'contratista', location: '/areas'),
        '/contractor/orders',
      );
    });

    test('residents-directory es solo de portero', () {
      expect(
        redirectForRestrictedRoute(role: 'portero', location: '/residents-directory'),
        isNull,
      );
      expect(
        redirectForRestrictedRoute(role: 'copropietario', location: '/residents-directory'),
        '/home',
      );
    });

    test('access-requests/new (portero) no se confunde con access-request/:id (copropietario)', () {
      expect(
        redirectForRestrictedRoute(role: 'portero', location: '/access-requests/new'),
        isNull,
      );
      expect(
        redirectForRestrictedRoute(role: 'copropietario', location: '/access-requests/new'),
        '/home',
      );
      expect(
        redirectForRestrictedRoute(role: 'copropietario', location: '/access-request/42'),
        isNull,
      );
      expect(
        redirectForRestrictedRoute(role: 'portero', location: '/access-request/42'),
        '/porteria-home',
      );
    });

    test('my-badge permite los 4 roles de staff, no a copropietario/portero/contratista', () {
      for (final role in ['administrador', 'auxiliar_contable', 'consejo', 'revisor_fiscal']) {
        expect(
          redirectForRestrictedRoute(role: role, location: '/my-badge'),
          isNull,
          reason: '$role debería poder ver /my-badge',
        );
      }
      expect(
        redirectForRestrictedRoute(role: 'copropietario', location: '/my-badge'),
        '/home',
      );
    });
  });

  group('homeRouteForRole', () {
    test('contratista va a sus órdenes', () {
      expect(homeRouteForRole('contratista'), '/contractor/orders');
    });

    test('portero va a su panel', () {
      expect(homeRouteForRole('portero'), '/porteria-home');
    });

    test('el resto de roles va a /home', () {
      for (final role in ['copropietario', 'administrador', 'auxiliar_contable', 'consejo', 'revisor_fiscal']) {
        expect(homeRouteForRole(role), '/home');
      }
    });
  });
}
