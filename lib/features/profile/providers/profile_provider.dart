import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';
import '../models/resident_profile.dart';

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, ResidentProfile?>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<ResidentProfile?> {
  @override
  Future<ResidentProfile?> build() async {
    return ref.read(profileRepositoryProvider).getProfile();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await ref.read(profileRepositoryProvider).updateProfile(data);
    await refresh();
  }

  Future<void> changePassword(String current, String newPassword) async {
    await ref
        .read(profileRepositoryProvider)
        .changePassword(current, newPassword);
  }

  Future<void> addVehicle(Map<String, dynamic> data) async {
    final vehicle =
        await ref.read(profileRepositoryProvider).addVehicle(data);
    state = state.whenData(
      (profile) => profile == null
          ? profile
          : ResidentProfile(
              id: profile.id,
              name: profile.name,
              email: profile.email,
              phone: profile.phone,
              apartmentNumber: profile.apartmentNumber,
              tower: profile.tower,
              vehicles: [...profile.vehicles, vehicle],
              pets: profile.pets,
            ),
    );
  }

  Future<void> deleteVehicle(int id) async {
    await ref.read(profileRepositoryProvider).deleteVehicle(id);
    state = state.whenData(
      (profile) => profile == null
          ? profile
          : ResidentProfile(
              id: profile.id,
              name: profile.name,
              email: profile.email,
              phone: profile.phone,
              apartmentNumber: profile.apartmentNumber,
              tower: profile.tower,
              vehicles:
                  profile.vehicles.where((v) => v.id != id).toList(),
              pets: profile.pets,
            ),
    );
  }

  Future<void> addPet(Map<String, dynamic> data) async {
    final pet = await ref.read(profileRepositoryProvider).addPet(data);
    state = state.whenData(
      (profile) => profile == null
          ? profile
          : ResidentProfile(
              id: profile.id,
              name: profile.name,
              email: profile.email,
              phone: profile.phone,
              apartmentNumber: profile.apartmentNumber,
              tower: profile.tower,
              vehicles: profile.vehicles,
              pets: [...profile.pets, pet],
            ),
    );
  }

  Future<void> deletePet(int id) async {
    await ref.read(profileRepositoryProvider).deletePet(id);
    state = state.whenData(
      (profile) => profile == null
          ? profile
          : ResidentProfile(
              id: profile.id,
              name: profile.name,
              email: profile.email,
              phone: profile.phone,
              apartmentNumber: profile.apartmentNumber,
              tower: profile.tower,
              vehicles: profile.vehicles,
              pets: profile.pets.where((p) => p.id != id).toList(),
            ),
    );
  }
}
