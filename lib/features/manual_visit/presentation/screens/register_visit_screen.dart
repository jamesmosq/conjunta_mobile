import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/apartment_lookup.dart';
import '../../../../core/widgets/apartment_picker.dart';
import '../../data/manual_visit_repository.dart';

class RegisterVisitScreen extends ConsumerStatefulWidget {
  const RegisterVisitScreen({super.key});

  @override
  ConsumerState<RegisterVisitScreen> createState() =>
      _RegisterVisitScreenState();
}

class _RegisterVisitScreenState extends ConsumerState<RegisterVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  final _plateController = TextEditingController();

  ApartmentLookup? _apartment;
  String _accessType = 'visitor';
  String _vehicleType = 'car';
  bool _sending = false;
  bool _searchingPlate = false;

  static const _accessTypes = [
    ('visitor', 'Visitante'),
    ('domestic', 'Doméstico'),
    ('delivery', 'Domicilio'),
    ('contractor', 'Contratista'),
    ('moving', 'Mudanza'),
  ];

  static const _vehicleTypes = [
    ('car', 'Carro'),
    ('moto', 'Moto'),
    ('bike', 'Bicicleta'),
    ('bicycle', 'Bicicleta eléctrica'),
    ('truck', 'Camión'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar entrada')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _documentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de documento (opcional)',
                  prefixIcon: Icon(Icons.numbers_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ApartmentPicker(
                // Fuerza a ApartmentPicker a re-leer `selected` cuando lo
                // llenamos nosotros (búsqueda por placa) — el widget solo
                // inicializa su campo de texto desde `selected` en
                // initState(), así que sin cambiar la key no se entera de
                // una selección hecha por fuera del propio picker.
                key: ValueKey(_apartment?.id),
                selected: _apartment,
                onSelected: (apt) => setState(() => _apartment = apt),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _accessType,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la visita',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _accessTypes
                    .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _accessType = v ?? 'visitor'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                // Sin esto el dropdown de tipo de vehículo de abajo (que
                // depende de este texto) solo aparecía cuando algún otro
                // campo disparaba un setState — escribir la placa por sí
                // sola no lo revelaba.
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Placa del vehículo (opcional)',
                  hintText: 'ABC123',
                  prefixIcon: const Icon(Icons.directions_car_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchingPlate
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: 'Buscar apartamento por placa',
                          onPressed: _plateController.text.trim().isEmpty
                              ? null
                              : _searchByPlate,
                        ),
                ),
              ),
              if (_plateController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _vehicleType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de vehículo',
                    border: OutlineInputBorder(),
                  ),
                  items: _vehicleTypes
                      .map((t) =>
                          DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                      .toList(),
                  onChanged: (v) => setState(() => _vehicleType = v ?? 'car'),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.login),
                  label: Text(_sending ? 'Registrando...' : 'Registrar entrada'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _searchByPlate() async {
    final plate = _plateController.text.trim();
    if (plate.isEmpty) return;

    setState(() => _searchingPlate = true);
    try {
      final apartment = await ref
          .read(manualVisitRepositoryProvider)
          .findApartmentByPlate(plate);

      if (!mounted) return;

      if (apartment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay ningún vehículo registrado con esa placa.'),
          ),
        );
        return;
      }

      setState(() => _apartment = apartment);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Encontrado: Apto ${apartment.fullIdentifier}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo buscar la placa. Intenta de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _searchingPlate = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_apartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el apartamento destino.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final result = await ref.read(manualVisitRepositoryProvider).create(
            visitorName: _nameController.text.trim(),
            apartmentId: _apartment!.id,
            documentNumber: _documentController.text.trim(),
            accessType: _accessType,
            vehiclePlate: _plateController.text.trim(),
            vehicleType:
                _plateController.text.trim().isEmpty ? null : _vehicleType,
          );

      if (!mounted) return;

      if (result.blacklisted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.red.shade50,
            title: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Expanded(child: Text('Acceso denegado')),
              ],
            ),
            content: Text(
              result.alert ??
                  'Esta persona está en la lista de no autorizados.',
              style: TextStyle(color: Colors.red.shade900),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.parkingAssigned
                ? '${result.visitorName} registrado — parqueadero asignado.'
                : '${result.visitorName} registrado correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo registrar la entrada. Intenta de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
