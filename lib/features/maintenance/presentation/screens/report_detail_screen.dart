import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../models/maintenance_request.dart';
import '../../providers/maintenance_provider.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.request});

  final MaintenanceRequest? request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (request == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Reporte no encontrado')),
      );
    }
    final r = request!;

    return Scaffold(
      appBar: AppBar(title: Text(r.typeLabel)),
      body: ListView(
        children: [
          _HeaderCard(request: r),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Seguimiento',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          _TimelineSection(requestId: r.id),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.request});
  final MaintenanceRequest request;

  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'es');

  @override
  Widget build(BuildContext context) {
    String dateStr = '';
    try {
      dateStr = _dateFmt.format(
          DateTime.parse(request.createdAt).toLocal());
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip.forMaintenanceStatus(request.status),
                const Spacer(),
                if (request.urgency == 'urgent')
                  const StatusChip(
                      label: 'Urgente', color: Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            Text(request.description,
                style:
                    const TextStyle(fontSize: 15, height: 1.5)),
            if (request.location != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(request.location!,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(dateStr,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13)),
              ],
            ),
            if (request.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Fotos adjuntas',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: request.photoUrls.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, i) => _PhotoThumbnail(
                    url: request.photoUrls[i],
                    allUrls: request.photoUrls,
                    initialIndex: i,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.url,
    required this.allUrls,
    required this.initialIndex,
  });

  final String url;
  final List<String> allUrls;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showGallery(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 110,
          height: 110,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 110,
            height: 110,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 110,
            height: 110,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.broken_image_outlined,
                color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void _showGallery(BuildContext context) {
    final pageCtrl = PageController(initialPage: initialIndex);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: pageCtrl,
              itemCount: allUrls.length,
              itemBuilder: (_, i) => InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: allUrls[i],
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 64),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineSection extends ConsumerWidget {
  const _TimelineSection({required this.requestId});
  final int requestId;

  static final _dtFmt = DateFormat('dd/MM/yyyy HH:mm', 'es');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineProvider(requestId));
    return AsyncValueWidget(
      value: timelineAsync,
      data: (entries) {
        if (entries.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sin movimientos aún.',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(entries.length, (i) {
              final e = entries[i];
              final isLast = i == entries.length - 1;
              String dtStr = '';
              try {
                dtStr = _dtFmt.format(
                    DateTime.parse(e.occurredAt).toLocal());
              } catch (_) {}

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Línea vertical + punto
                    SizedBox(
                      width: 32,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: isLast ? 0 : 20),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (e.toStatus != null)
                              StatusChip.forMaintenanceStatus(
                                  e.toStatus!),
                            const SizedBox(height: 4),
                            Text(dtStr,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey)),
                            if (e.note != null) ...[
                              const SizedBox(height: 4),
                              Text(e.note!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
