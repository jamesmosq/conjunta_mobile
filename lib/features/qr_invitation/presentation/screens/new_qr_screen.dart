import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../features/auth/providers/auth_provider.dart';
import '../../providers/qr_invitation_provider.dart';

class NewQrScreen extends ConsumerStatefulWidget {
  const NewQrScreen({super.key});

  @override
  ConsumerState<NewQrScreen> createState() => _NewQrScreenState();
}

class _NewQrScreenState extends ConsumerState<NewQrScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _docNumberController = TextEditingController();

  String _docType = 'cc';
  DateTime? _validFrom;
  DateTime? _validUntil;

  static const _docTypes = [
    ('cc', 'Cédula de Ciudadanía'),
    ('pasaporte', 'Pasaporte'),
    ('ce', 'Cédula de Extranjería'),
  ];

  @override
  void initState() {
    super.initState();
    // Default: today → tomorrow
    final now = DateTime.now();
    _validFrom = DateTime(now.year, now.month, now.day);
    _validUntil = _validFrom!.add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _docNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = ref.watch(qrInvitationProvider).isCreating;
    final fmtDate = DateFormat('dd/MM/yyyy', 'es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Invitación QR'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('Datos del visitante'),
              const SizedBox(height: 12),

              // Nombre
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),

              // Tipo de documento
              DropdownButtonFormField<String>(
                value: _docType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de documento *',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _docTypes
                    .map((t) => DropdownMenuItem(
                          value: t.$1,
                          child: Text(t.$2),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _docType = v ?? 'cc'),
              ),
              const SizedBox(height: 16),

              // Número de documento
              TextFormField(
                controller: _docNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de documento *',
                  prefixIcon: Icon(Icons.numbers_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'El número es obligatorio' : null,
              ),
              const SizedBox(height: 24),

              _SectionLabel('Período de validez (máx. 7 días)'),
              const SizedBox(height: 12),

              // Dates row
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Válido desde',
                      value: _validFrom != null ? fmtDate.format(_validFrom!) : null,
                      onTap: () => _pickDate(isFrom: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Válido hasta',
                      value: _validUntil != null ? fmtDate.format(_validUntil!) : null,
                      onTap: () => _pickDate(isFrom: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Error display
              if (ref.watch(qrInvitationProvider).error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ref.watch(qrInvitationProvider).error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isCreating ? null : _submit,
                  icon: isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.qr_code_2),
                  label: Text(
                      isCreating ? 'Generando...' : 'Generar invitación QR'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
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

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom
        ? (_validFrom ?? now)
        : (_validUntil ?? now.add(const Duration(days: 1)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isFrom ? now : (_validFrom ?? now),
      lastDate: isFrom
          ? now.add(const Duration(days: 30))
          : (_validFrom ?? now).add(const Duration(days: 7)),
      locale: const Locale('es', 'CO'),
    );

    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _validFrom = picked;
        // If until is before new from, reset it
        if (_validUntil != null && !_validUntil!.isAfter(picked)) {
          _validUntil = picked.add(const Duration(days: 1));
        }
      } else {
        _validUntil = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_validFrom == null || _validUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona las fechas de validez.')),
      );
      return;
    }

    if (!_validUntil!.isAfter(_validFrom!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha final debe ser posterior a la inicial.'),
        ),
      );
      return;
    }

    final user = ref.read(authStateProvider).value;
    final apartmentId = user?.apartmentId;
    if (apartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se encontró tu apartamento. Recarga la app.')),
      );
      return;
    }

    final qr = await ref.read(qrInvitationProvider.notifier).create(
          apartmentId: apartmentId,
          visitorName: _nameController.text.trim(),
          documentType: _docType,
          documentNumber: _docNumberController.text.trim(),
          validFrom: _validFrom!.toIso8601String().split('T').first,
          validUntil: _validUntil!.toIso8601String().split('T').first,
        );

    if (!mounted) return;

    if (qr != null) {
      // Navigate to detail (replace so back goes to history)
      context.pushReplacement('/qr-invitations/${qr.id}', extra: qr);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.deepPurple.shade700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? 'Seleccionar',
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null
                          ? Colors.black87
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
