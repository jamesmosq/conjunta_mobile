import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../models/blacklist_entry.dart';
import '../../providers/blacklist_provider.dart';

class BlacklistScreen extends ConsumerStatefulWidget {
  const BlacklistScreen({super.key});

  @override
  ConsumerState<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends ConsumerState<BlacklistScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(blacklistProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('No autorizados')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o documento',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _query = '';
                        }),
                      ),
              ),
            ),
          ),
          Expanded(
            child: AsyncValueWidget<List<BlacklistEntry>>(
              value: listAsync,
              data: (list) {
                final filtered = _query.isEmpty
                    ? list
                    : list
                        .where((e) =>
                            e.name.toLowerCase().contains(_query) ||
                            e.documentNumber.toLowerCase().contains(_query))
                        .toList();
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(blacklistProvider.notifier).refresh(),
                  child: filtered.isEmpty
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 80),
                              child: Center(
                                child: Text(
                                  list.isEmpty
                                      ? 'No hay personas en la lista de no autorizados'
                                      : 'Sin resultados para "$_query"',
                                  style:
                                      TextStyle(color: Colors.grey.shade500),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFEBEE),
                                child: Icon(Icons.block, color: Colors.red),
                              ),
                              title: Text(filtered[i].name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle:
                                  Text('Documento: ${filtered[i].documentNumber}'),
                            ),
                          ),
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
