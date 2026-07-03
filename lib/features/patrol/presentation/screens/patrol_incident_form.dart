import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/patrol_provider.dart';

class PatrolIncidentForm extends ConsumerStatefulWidget {
  const PatrolIncidentForm({
    super.key,
    required this.sessionId,
    this.checkpointId,
  });

  final int sessionId;
  final int? checkpointId;

  @override
  ConsumerState<PatrolIncidentForm> createState() => _PatrolIncidentFormState();
}

class _PatrolIncidentFormState extends ConsumerState<PatrolIncidentForm> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  String _severity = 'medium';
  File? _photo;
  bool _submitting = false;

  static const _severities = [
    ('low', 'Baja', Colors.green),
    ('medium', 'Media', Colors.orange),
    ('high', 'Alta', Colors.red),
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Incidencia'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.checkpointId != null) _CheckpointBadge(widget.checkpointId!),
              const SizedBox(height: 20),
              Text('Descripción', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Describa la incidencia con el mayor detalle posible...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'La descripción es obligatoria' : null,
              ),
              const SizedBox(height: 20),
              Text('Severidad', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              Row(
                children: _severities.map((s) {
                  final (value, label, color) = s;
                  final selected = _severity == value;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        selectedColor: color.withValues(alpha: 0.2),
                        side: BorderSide(
                          color: selected ? color : Colors.grey.shade300,
                          width: selected ? 2 : 1,
                        ),
                        labelStyle: TextStyle(
                          color: selected ? color : Colors.grey.shade600,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _severity = value),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Foto (opcional)', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              _PhotoSelector(
                photo: _photo,
                onTakePhoto: _takePhoto,
                onPickPhoto: _pickPhoto,
                onRemove: () => setState(() => _photo = null),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_submitting ? 'Enviando...' : 'Reportar incidencia'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (xFile != null) setState(() => _photo = File(xFile.path));
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xFile != null) setState(() => _photo = File(xFile.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final ok = await ref.read(patrolProvider.notifier).reportIncident(
          description: _descController.text.trim(),
          severity: _severity,
          checkpointId: widget.checkpointId,
          photo: _photo,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incidencia reportada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      final error = ref.read(patrolProvider).error ?? 'Error al reportar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }
}

class _CheckpointBadge extends StatelessWidget {
  const _CheckpointBadge(this.checkpointId);

  final int checkpointId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Text(
            'Checkpoint #$checkpointId',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSelector extends StatelessWidget {
  const _PhotoSelector({
    required this.photo,
    required this.onTakePhoto,
    required this.onPickPhoto,
    required this.onRemove,
  });

  final File? photo;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              photo!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTakePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Cámara'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPickPhoto,
            icon: const Icon(Icons.photo_library),
            label: const Text('Galería'),
          ),
        ),
      ],
    );
  }
}
