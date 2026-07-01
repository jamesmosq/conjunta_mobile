import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/user_session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(apiClientProvider).dio,
    ref.read(secureStorageProvider),
  );
});

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;

  Future<UserSession> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
      'device_name': deviceName,
    });
    final session = UserSession.fromJson(response.data as Map<String, dynamic>);
    await _storage.saveSession(
      token: session.token,
      userId: session.user.id,
      role: session.user.role,
      tenantId: session.user.tenantId,
      apartmentId: session.user.apartmentId,
      name: session.user.name,
      email: session.user.email,
    );
    return session;
  }

  Future<AuthUser> me() async {
    final response = await _dio.get('/auth/me');
    final data = response.data as Map<String, dynamic>;
    return AuthUser.fromJson(data['data'] as Map<String, dynamic>? ?? data);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } finally {
      await _storage.clearSession();
    }
  }

  Future<void> updateFcmToken(String token) async {
    await _dio.post('/auth/fcm-token', data: {'fcm_token': token});
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<SessionData?> getStoredSession() => _storage.getSession();
}
