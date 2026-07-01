import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/resident_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(apiClientProvider).dio);
});

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<ResidentProfile> getProfile() async {
    final response = await _dio.get('/profile');
    final data = response.data;
    return ResidentProfile.fromJson(
        data is Map<String, dynamic> ? data : data['data'] as Map<String, dynamic>);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _dio.put('/profile', data: data);
  }

  Future<void> changePassword(String current, String newPassword) async {
    await _dio.put('/profile/password', data: {
      'current_password': current,
      'password': newPassword,
      'password_confirmation': newPassword,
    });
  }

  Future<Vehicle> addVehicle(Map<String, dynamic> data) async {
    final response = await _dio.post('/vehicles', data: data);
    return Vehicle.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteVehicle(int vehicleId) async {
    await _dio.delete('/vehicles/$vehicleId');
  }

  Future<Pet> addPet(Map<String, dynamic> data) async {
    final response = await _dio.post('/pets', data: data);
    return Pet.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deletePet(int petId) async {
    await _dio.delete('/pets/$petId');
  }
}
