import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/apartments_repository.dart';
import '../models/apartment_lookup.dart';

/// Campo de búsqueda de apartamento con autocompletado simple — usado por
/// portero en flujos donde necesita indicar el apartamento destino
/// (registrar entrada manual, registrar paquete) sin conocer su ID.
class ApartmentPicker extends ConsumerStatefulWidget {
  const ApartmentPicker({
    super.key,
    required this.onSelected,
    this.selected,
  });

  final ValueChanged<ApartmentLookup> onSelected;
  final ApartmentLookup? selected;

  @override
  ConsumerState<ApartmentPicker> createState() => _ApartmentPickerState();
}

class _ApartmentPickerState extends ConsumerState<ApartmentPicker> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<ApartmentLookup> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.selected != null) {
      _controller.text = widget.selected!.fullIdentifier;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _loading = true);
      try {
        final results =
            await ref.read(apartmentsRepositoryProvider).search(value);
        if (mounted) setState(() => _results = results);
      } catch (_) {
        if (mounted) setState(() => _results = []);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: 'Apartamento *',
            hintText: 'Buscar por número...',
            prefixIcon: const Icon(Icons.apartment_outlined),
            border: const OutlineInputBorder(),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
          ),
        ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final apt = _results[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.apartment_outlined, size: 20),
                  title: Text(apt.fullIdentifier),
                  onTap: () {
                    _controller.text = apt.fullIdentifier;
                    setState(() => _results = []);
                    FocusScope.of(context).unfocus();
                    widget.onSelected(apt);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
