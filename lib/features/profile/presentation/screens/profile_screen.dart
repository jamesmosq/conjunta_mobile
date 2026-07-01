import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/resident_profile.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: AsyncValueWidget(
        value: profileAsync,
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No se pudo cargar el perfil.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(profileProvider.notifier).refresh(),
            child: ListView(
              children: [
                _ProfileHeader(profile: profile, cs: cs),
                if (profile.apartmentNumber != null) ...[
                  _SectionTitle('Apartamento'),
                  ListTile(
                    leading: const Icon(Icons.apartment_outlined),
                    title: Text(
                      '${profile.tower != null ? "Torre ${profile.tower} — " : ""}Apto ${profile.apartmentNumber}',
                    ),
                  ),
                ],
                _SectionTitle('Vehículos'),
                if (profile.vehicles.isEmpty)
                  _EmptyHint('Sin vehículos registrados'),
                ...profile.vehicles.map((v) => _VehicleTile(vehicle: v)),
                ListTile(
                  leading: Icon(Icons.add_circle_outline, color: cs.primary),
                  title: Text('Agregar vehículo',
                      style: TextStyle(color: cs.primary)),
                  onTap: () => _showAddVehicleSheet(context, ref),
                ),
                _SectionTitle('Mascotas'),
                if (profile.pets.isEmpty)
                  _EmptyHint('Sin mascotas registradas'),
                ...profile.pets.map((p) => _PetTile(pet: p)),
                ListTile(
                  leading: Icon(Icons.add_circle_outline, color: cs.primary),
                  title: Text('Agregar mascota',
                      style: TextStyle(color: cs.primary)),
                  onTap: () => _showAddPetSheet(context, ref),
                ),
                _SectionTitle('Seguridad'),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Cambiar contraseña'),
                  trailing:
                      const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _showChangePasswordSheet(context, ref),
                ),
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Cerrar sesión',
                      style: TextStyle(color: Colors.red)),
                  onTap: () => _confirmLogout(context, ref),
                ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
      floatingActionButton: profileAsync.valueOrNull != null
          ? FloatingActionButton.extended(
              onPressed: () => context.push(
                '/profile/edit',
                extra: profileAsync.value!,
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            )
          : null,
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas salir?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }

  void _showAddVehicleSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddVehicleSheet(ref: ref),
    );
  }

  void _showAddPetSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddPetSheet(ref: ref),
    );
  }

  void _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ChangePasswordSheet(ref: ref),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.cs});

  final ResidentProfile profile;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final initials = profile.name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer,
            cs.secondaryContainer,
          ],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: cs.primary,
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: TextStyle(
                fontSize: 24,
                color: cs.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(profile.email,
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 13)),
                if (profile.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(profile.phone!,
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(text,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13)),
    );
  }
}

// ─── Vehicle tile ─────────────────────────────────────────────────────────────

class _VehicleTile extends ConsumerWidget {
  const _VehicleTile({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = switch (vehicle.type) {
      'motorcycle' => Icons.two_wheeler_outlined,
      'bicycle' => Icons.directions_bike_outlined,
      _ => Icons.directions_car_outlined,
    };

    return ListTile(
      leading: Icon(icon),
      title: Text(vehicle.plate,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text([
        vehicle.typeLabel,
        if (vehicle.brand != null) vehicle.brand!,
        if (vehicle.color != null) vehicle.color!,
      ].join(' · ')),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        tooltip: 'Eliminar',
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Eliminar vehículo'),
              content: Text('¿Eliminar ${vehicle.plate}?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Eliminar',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (ok == true) {
            await ref
                .read(profileProvider.notifier)
                .deleteVehicle(vehicle.id);
          }
        },
      ),
    );
  }
}

// ─── Pet tile ─────────────────────────────────────────────────────────────────

class _PetTile extends ConsumerWidget {
  const _PetTile({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.pets_outlined),
      title: Text(pet.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text([
        pet.speciesLabel,
        if (pet.breed != null) pet.breed!,
      ].join(' · ')),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        tooltip: 'Eliminar',
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Eliminar mascota'),
              content: Text('¿Eliminar a ${pet.name}?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Eliminar',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (ok == true) {
            await ref.read(profileProvider.notifier).deletePet(pet.id);
          }
        },
      ),
    );
  }
}

// ─── Add Vehicle bottom sheet ─────────────────────────────────────────────────

class _AddVehicleSheet extends StatefulWidget {
  const _AddVehicleSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<_AddVehicleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  String _type = 'car';
  bool _saving = false;

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.ref.read(profileProvider.notifier).addVehicle({
        'plate': _plateCtrl.text.trim().toUpperCase(),
        'type': _type,
        if (_brandCtrl.text.trim().isNotEmpty) 'brand': _brandCtrl.text.trim(),
        if (_colorCtrl.text.trim().isNotEmpty) 'color': _colorCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al agregar el vehículo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Agregar vehículo',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                  labelText: 'Tipo de vehículo',
                  prefixIcon: Icon(Icons.commute_outlined)),
              items: const [
                DropdownMenuItem(value: 'car', child: Text('Carro')),
                DropdownMenuItem(
                    value: 'motorcycle', child: Text('Motocicleta')),
                DropdownMenuItem(
                    value: 'bicycle', child: Text('Bicicleta')),
                DropdownMenuItem(value: 'truck', child: Text('Camioneta')),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _plateCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'Placa *',
                  prefixIcon: Icon(Icons.pin_outlined),
                  hintText: 'ABC123'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'La placa es requerida';
                if (v.trim().length < 5) return 'Placa muy corta';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brandCtrl,
              decoration: const InputDecoration(
                  labelText: 'Marca (opcional)',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  hintText: 'Chevrolet, Yamaha…'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _colorCtrl,
              decoration: const InputDecoration(
                  labelText: 'Color (opcional)',
                  prefixIcon: Icon(Icons.palette_outlined),
                  hintText: 'Blanco, Negro…'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar vehículo'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Pet bottom sheet ─────────────────────────────────────────────────────

class _AddPetSheet extends StatefulWidget {
  const _AddPetSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_AddPetSheet> createState() => _AddPetSheetState();
}

class _AddPetSheetState extends State<_AddPetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  String _species = 'dog';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.ref.read(profileProvider.notifier).addPet({
        'name': _nameCtrl.text.trim(),
        'species': _species,
        if (_breedCtrl.text.trim().isNotEmpty) 'breed': _breedCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al agregar la mascota.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Agregar mascota',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.pets_outlined)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _species,
              decoration: const InputDecoration(
                  labelText: 'Especie',
                  prefixIcon: Icon(Icons.category_outlined)),
              items: const [
                DropdownMenuItem(value: 'dog', child: Text('Perro')),
                DropdownMenuItem(value: 'cat', child: Text('Gato')),
                DropdownMenuItem(value: 'bird', child: Text('Ave')),
                DropdownMenuItem(value: 'other', child: Text('Otro')),
              ],
              onChanged: (v) => setState(() => _species = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _breedCtrl,
              decoration: const InputDecoration(
                  labelText: 'Raza (opcional)',
                  prefixIcon: Icon(Icons.info_outline),
                  hintText: 'Golden Retriever, Siamés…'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar mascota'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Change Password bottom sheet ────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.ref
          .read(profileProvider.notifier)
          .changePassword(_currentCtrl.text, _newCtrl.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada correctamente.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Error al cambiar la contraseña. Verifica que la contraseña actual sea correcta.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Cambiar contraseña',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currentCtrl,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Contraseña actual *',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: _ToggleVisibility(
                  obscure: _obscureCurrent,
                  onTap: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Ingresa tu contraseña actual' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña *',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: _ToggleVisibility(
                  obscure: _obscureNew,
                  onTap: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa una nueva contraseña';
                if (v.length < 8) return 'Mínimo 8 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirmar nueva contraseña *',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: _ToggleVisibility(
                  obscure: _obscureConfirm,
                  onTap: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirma la nueva contraseña';
                if (v != _newCtrl.text) return 'Las contraseñas no coinciden';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Cambiar contraseña'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleVisibility extends StatelessWidget {
  const _ToggleVisibility({required this.obscure, required this.onTap});

  final bool obscure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
      onPressed: onTap,
    );
  }
}
