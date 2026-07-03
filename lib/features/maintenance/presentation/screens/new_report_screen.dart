import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/providers/auth_provider.dart';
import '../../providers/maintenance_provider.dart';

class NewReportScreen extends ConsumerStatefulWidget {
  const NewReportScreen({super.key});

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();

  String _locationType = 'apartment';
  bool _loading = false;

  static const _categories = [
    ('plomeria', 'Plomería', Icons.water_drop_outlined),
    ('electricidad', 'Electricidad', Icons.electrical_services_outlined),
    ('estructura', 'Estructura', Icons.foundation_outlined),
    ('gas', 'Gas', Icons.local_fire_department_outlined),
    ('aseo', 'Aseo', Icons.cleaning_services_outlined),
    ('otro', 'Otro', Icons.build_outlined),
  ];

  String _category = 'plomeria';

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
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
      final categoryLabel = _categories
          .firstWhere((c) => c.$1 == _category,
              orElse: () => ('otro', 'Otro', Icons.build_outlined))
          .$2;
      final fullDescription = '[$categoryLabel] ${_descriptionCtrl.text.trim()}';

      await ref.read(maintenanceRequestsProvider.notifier).create({
        'type': 'corrective',
        'location_type': _locationType,
        if (_locationType == 'apartment') 'apartment_id': apartmentId,
        'description': fullDescription,
      });
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
            // Categoría
            const Text('Categoría del problema',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final (value, label, icon) = c;
                final selected = _category == value;
                return FilterChip(
                  avatar: Icon(icon,
                      size: 16,
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null),
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = value),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Ubicación
            const Text('Ubicación',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'apartment',
                    label: Text('Mi apartamento'),
                    icon: Icon(Icons.home_outlined)),
                ButtonSegment(
                    value: 'common_area',
                    label: Text('Área común'),
                    icon: Icon(Icons.business_outlined)),
              ],
              selected: {_locationType},
              onSelectionChanged: (sel) =>
                  setState(() => _locationType = sel.first),
            ),
            const SizedBox(height: 20),

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
