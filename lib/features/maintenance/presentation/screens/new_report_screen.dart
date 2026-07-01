import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../features/auth/providers/auth_provider.dart';
import '../../providers/maintenance_provider.dart';

class NewReportScreen extends ConsumerStatefulWidget {
  const NewReportScreen({super.key});

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _picker = ImagePicker();

  String _type = 'plomeria';
  String _urgency = 'normal';
  bool _loading = false;
  final List<XFile> _photos = [];

  static const _maxPhotos = 5;

  static const _types = [
    ('plomeria', 'Plomería', Icons.water_drop_outlined),
    ('electricidad', 'Electricidad', Icons.electrical_services_outlined),
    ('estructura', 'Estructura', Icons.foundation_outlined),
    ('gas', 'Gas', Icons.local_fire_department_outlined),
    ('aseo', 'Aseo', Icons.cleaning_services_outlined),
    ('otro', 'Otro', Icons.build_outlined),
  ];

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Máximo $_maxPhotos fotos por reporte')),
      );
      return;
    }
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1280,
      );
      if (file != null && mounted) {
        setState(() => _photos.add(file));
      }
    } catch (_) {}
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final apartmentId = ref.read(authStateProvider).value?.apartmentId;
    if (apartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes un apartamento asignado.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(maintenanceRequestsProvider.notifier).create(
        {
          'apartment_id': apartmentId,
          'type': _type,
          'urgency': _urgency,
          'location': _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
          'description': _descriptionCtrl.text.trim(),
        },
        photos: List.of(_photos),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte enviado correctamente')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error: ${e.toString().replaceAll('Exception: ', '')}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo reporte')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tipo
            const Text('Tipo de problema',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final (value, label, icon) = t;
                final selected = _type == value;
                return FilterChip(
                  avatar: Icon(icon,
                      size: 16,
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null),
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setState(() => _type = value),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Urgencia
            const Text('Urgencia',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'normal',
                    label: Text('Normal'),
                    icon: Icon(Icons.info_outline)),
                ButtonSegment(
                    value: 'urgent',
                    label: Text('Urgente'),
                    icon: Icon(Icons.priority_high)),
              ],
              selected: {_urgency},
              onSelectionChanged: (sel) =>
                  setState(() => _urgency = sel.first),
            ),
            const SizedBox(height: 20),

            // Ubicación
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Ubicación del problema',
                hintText: 'Ej: Baño principal, cocina, área común...',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción *',
                hintText:
                    'Describe el problema con el mayor detalle posible',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              minLines: 4,
              maxLines: 8,
              maxLength: 500,
              validator: (v) {
                if (v == null || v.trim().length < 20) {
                  return 'La descripción debe tener al menos 20 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Fotos
            Row(
              children: [
                const Text('Fotos',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(width: 8),
                Text(
                  '${_photos.length}/$_maxPhotos',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Adjunta fotos del daño para facilitar el diagnóstico',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 12),
            _PhotoGrid(
              photos: _photos,
              canAdd: _photos.length < _maxPhotos,
              onAdd: _showPhotoSourceSheet,
              onRemove: _removePhoto,
            ),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_outlined),
              label: const Text('Enviar reporte'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.photos,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
  });

  final List<XFile> photos;
  final bool canAdd;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...List.generate(
          photos.length,
          (i) => _PhotoTile(
            file: photos[i],
            onRemove: () => onRemove(i),
          ),
        ),
        if (canAdd) _AddPhotoTile(onTap: onAdd),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(file.path),
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close,
                  size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              'Agregar',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
