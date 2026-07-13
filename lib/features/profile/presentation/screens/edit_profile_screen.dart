import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/resident_profile.dart';
import '../../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final ResidentProfile profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name)
      ..addListener(_onChanged);
    _phoneCtrl = TextEditingController(text: widget.profile.phone ?? '')
      ..addListener(_onChanged);
  }

  void _onChanged() => setState(() => _hasChanges = true);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).updateProfile({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar los cambios.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar cambios'),
        content:
            const Text('¿Deseas salir sin guardar los cambios?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continuar editando')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final should = await _onWillPop();
          if (should && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar perfil'),
          actions: [
            if (_saving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              TextButton(
                onPressed: _hasChanges ? _save : null,
                child: Text(
                  'Guardar',
                  style: TextStyle(
                    color: _hasChanges ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _AvatarPreview(name: _nameCtrl.text, cs: cs),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'El nombre es requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono celular',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '300 123 4567',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 7) return 'Teléfono inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: widget.profile.email,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withAlpha(120),
                  helperText: 'El correo no se puede modificar aquí.',
                ),
              ),
              if (widget.profile.apartmentNumber != null) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue:
                      '${widget.profile.tower != null ? "Torre ${widget.profile.tower} — " : ""}Apto ${widget.profile.apartmentNumber}',
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Apartamento',
                    prefixIcon: const Icon(Icons.apartment_outlined),
                    filled: true,
                    fillColor:
                        cs.surfaceContainerHighest.withAlpha(120),
                    helperText: 'Modificar en administración.',
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: (_hasChanges && !_saving) ? _save : null,
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.name, required this.cs});

  final String name;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Center(
      child: CircleAvatar(
        radius: 44,
        backgroundColor: cs.primary,
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: TextStyle(
            fontSize: 28,
            color: cs.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
