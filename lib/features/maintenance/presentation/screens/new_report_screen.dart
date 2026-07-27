import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../areas/data/areas_repository.dart';
import '../../../areas/models/common_area.dart';
import '../../providers/maintenance_provider.dart';

class NewReportScreen extends ConsumerStatefulWidget {
  const NewReportScreen({super.key});

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();

  // Mejora 2 informe UI-UX: la administración solo gestiona áreas comunes —
  // el apartamento privado ya no es una ubicación válida para este reporte.
  int? _commonAreaId;
  bool _loading = false;
  List<CommonArea>? _areas;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    try {
      final areas = await ref.read(areasRepositoryProvider).getAreas();
      if (!mounted) return;
      setState(() => _areas = areas.where((a) => a.isActive).toList());
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'No se pudieron cargar las áreas comunes.');
    }
  }

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
    if (_commonAreaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el área común afectada.')),
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
        'location_type': 'common_area',
        'common_area_id': _commonAreaId,
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

            // Ubicación — solo áreas comunes, la administración no gestiona
            // daños dentro del apartamento privado (Mejora 2 informe UI-UX).
            const Text('Área común afectada',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            if (_loadError != null)
              Text(_loadError!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))
            else if (_areas == null)
              const Center(child: CircularProgressIndicator())
            else if (_areas!.isEmpty)
              Text('No hay áreas comunes configuradas.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13))
            else
              DropdownButtonFormField<int>(
                value: _commonAreaId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _areas!
                    .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                    .toList(),
                onChanged: (v) => setState(() => _commonAreaId = v),
                validator: (v) => v == null ? 'Selecciona el área común' : null,
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
