import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/porteria_provider.dart';

class NewPreAuthScreen extends ConsumerStatefulWidget {
  const NewPreAuthScreen({super.key});

  @override
  ConsumerState<NewPreAuthScreen> createState() => _NewPreAuthScreenState();
}

class _NewPreAuthScreenState extends ConsumerState<NewPreAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _documentCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();

  String _arrivalMode = 'walk';
  String? _vehicleType;
  String? _relationType;
  bool _isRecurring = false;
  DateTime? _expiresAt;
  DateTime? _expectedAt;

  // Recurring fields
  final List<bool> _allowedDays = List.filled(7, false);
  TimeOfDay? _allowedFrom;
  TimeOfDay? _allowedUntil;

  bool _loading = false;

  static const _vehicleTypes = [
    ('car', 'Carro'),
    ('moto', 'Moto'),
    ('bike', 'Bicicleta a motor'),
    ('bicycle', 'Bicicleta'),
    ('truck', 'Camión'),
  ];

  static const _relationTypes = [
    ('family', 'Familiar'),
    ('domestic', 'Empleado doméstico'),
    ('provider', 'Proveedor'),
    ('other', 'Otro'),
  ];

  static const _dayLabels = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

  final _dateFmt = DateFormat('dd/MM/yyyy', 'es');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _documentCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isExpires}) async {
    final initial = isExpires
        ? (_expiresAt ?? DateTime.now().add(const Duration(days: 30)))
        : (_expectedAt ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isExpires) {
          _expiresAt = picked;
        } else {
          _expectedAt = picked;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final initial = isFrom
        ? (_allowedFrom ?? const TimeOfDay(hour: 8, minute: 0))
        : (_allowedUntil ?? const TimeOfDay(hour: 18, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _allowedFrom = picked;
        } else {
          _allowedUntil = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isRecurring) {
      if (!_allowedDays.contains(true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona al menos un día permitido.')),
        );
        return;
      }
      if (_allowedFrom == null || _allowedUntil == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona las horas permitidas.')),
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final days = <int>[];
      for (var i = 0; i < 7; i++) {
        if (_allowedDays[i]) days.add(i);
      }

      await ref.read(preAuthorizationsProvider.notifier).create({
        'visitor_name': _nameCtrl.text.trim(),
        if (_documentCtrl.text.trim().isNotEmpty)
          'document_number': _documentCtrl.text.trim(),
        'arrival_mode': _arrivalMode,
        if (_arrivalMode == 'vehicle') ...{
          'vehicle_plate': _plateCtrl.text.trim(),
          'vehicle_type': _vehicleType,
        },
        if (_relationType != null) 'relation_type': _relationType,
        if (_expectedAt != null)
          'expected_at': _expectedAt!.toIso8601String(),
        if (_expiresAt != null)
          'expires_at': _expiresAt!.toIso8601String(),
        'is_recurring': _isRecurring,
        if (_isRecurring) ...{
          'allowed_days': days,
          'allowed_from': _formatTime(_allowedFrom!),
          'allowed_until': _formatTime(_allowedUntil!),
        },
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pre-autorización creada'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Pre-Autorización')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nombre
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del visitante *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),

            // Documento
            TextFormField(
              controller: _documentCtrl,
              decoration: const InputDecoration(
                labelText: 'Número de documento (opcional)',
                prefixIcon: Icon(Icons.numbers_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Modo de llegada
            DropdownButtonFormField<String>(
              value: _arrivalMode,
              decoration: const InputDecoration(
                labelText: 'Medio de llegada *',
                prefixIcon: Icon(Icons.directions_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'walk', child: Text('A pie')),
                DropdownMenuItem(value: 'vehicle', child: Text('Vehículo')),
              ],
              onChanged: (v) => setState(() {
                _arrivalMode = v!;
                if (v != 'vehicle') {
                  _vehicleType = null;
                  _plateCtrl.clear();
                }
              }),
            ),
            const SizedBox(height: 16),

            // Vehículo fields
            if (_arrivalMode == 'vehicle') ...[
              TextFormField(
                controller: _plateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Placa del vehículo *',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => _arrivalMode == 'vehicle' &&
                        (v == null || v.trim().isEmpty)
                    ? 'Requerido para vehículo'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _vehicleType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de vehículo *',
                  prefixIcon: Icon(Icons.commute_outlined),
                ),
                items: _vehicleTypes
                    .map((t) =>
                        DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                    .toList(),
                validator: (v) => _arrivalMode == 'vehicle' && v == null
                    ? 'Selecciona el tipo'
                    : null,
                onChanged: (v) => setState(() => _vehicleType = v),
              ),
              const SizedBox(height: 16),
            ],

            // Relación
            DropdownButtonFormField<String>(
              value: _relationType,
              decoration: const InputDecoration(
                labelText: 'Tipo de relación (opcional)',
                prefixIcon: Icon(Icons.group_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin especificar')),
                ..._relationTypes.map((t) =>
                    DropdownMenuItem(value: t.$1, child: Text(t.$2))),
              ],
              onChanged: (v) => setState(() => _relationType = v),
            ),
            const SizedBox(height: 16),

            // Fecha esperada
            _DatePickerTile(
              label: 'Visita esperada (opcional)',
              value: _expectedAt != null ? _dateFmt.format(_expectedAt!) : null,
              icon: Icons.event_outlined,
              onTap: () => _pickDate(isExpires: false),
              onClear: _expectedAt != null
                  ? () => setState(() => _expectedAt = null)
                  : null,
            ),
            const SizedBox(height: 16),

            // Fecha de vencimiento
            _DatePickerTile(
              label: 'Pre-autorización válida hasta (opcional)',
              value: _expiresAt != null ? _dateFmt.format(_expiresAt!) : null,
              icon: Icons.calendar_today_outlined,
              onTap: () => _pickDate(isExpires: true),
              onClear: _expiresAt != null
                  ? () => setState(() => _expiresAt = null)
                  : null,
            ),
            const SizedBox(height: 20),

            // Recurrente
            SwitchListTile(
              title: const Text('Visita recurrente'),
              subtitle: const Text('Permite acceso en días y horarios fijos'),
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
              contentPadding: EdgeInsets.zero,
            ),

            if (_isRecurring) ...[
              const SizedBox(height: 8),
              const Text('Días permitidos',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (i) {
                  return FilterChip(
                    label: Text(_dayLabels[i]),
                    selected: _allowedDays[i],
                    onSelected: (v) =>
                        setState(() => _allowedDays[i] = v),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TimeTile(
                      label: 'Desde',
                      value: _allowedFrom != null
                          ? _formatTime(_allowedFrom!)
                          : null,
                      onTap: () => _pickTime(isFrom: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeTile(
                      label: 'Hasta',
                      value: _allowedUntil != null
                          ? _formatTime(_allowedUntil!)
                          : null,
                      onTap: () => _pickTime(isFrom: false),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: onClear != null
              ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
              : null,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value ?? 'Toca para seleccionar',
          style: TextStyle(
            color: value != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_outlined, size: 16),
                const SizedBox(width: 4),
                Text(
                  value ?? '--:--',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: value != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
