import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/apartments_repository.dart';
import '../../../../core/models/apartment_residents.dart';

/// Directorio de residentes (QA #35) — portero necesita poder localizar el
/// apartamento de un propietario ante cualquier eventualidad, o al revés,
/// saber quién vive en un apartamento dado.
class ResidentsDirectoryScreen extends ConsumerStatefulWidget {
  const ResidentsDirectoryScreen({super.key});

  @override
  ConsumerState<ResidentsDirectoryScreen> createState() =>
      _ResidentsDirectoryScreenState();
}

class _ResidentsDirectoryScreenState
    extends ConsumerState<ResidentsDirectoryScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<ApartmentResidents> _results = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results =
          await ref.read(apartmentsRepositoryProvider).searchDirectory(query);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo cargar el directorio.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Directorio de residentes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                labelText: 'Buscar por apartamento o nombre',
                hintText: 'Ej: 304 o Camila',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(_error!),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => _search(_controller.text),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? const Center(
                            child: Text('No se encontraron resultados'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final apt = _results[i];
                              return ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.apartment_outlined),
                                ),
                                title: Text(apt.fullIdentifier),
                                subtitle: Text(
                                  apt.residentNames.isEmpty
                                      ? 'Sin residentes registrados'
                                      : apt.residentNames.join(', '),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
