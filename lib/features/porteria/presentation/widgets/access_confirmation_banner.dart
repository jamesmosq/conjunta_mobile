import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/access_event.dart';
import '../../providers/live_access_provider.dart';

/// Overlay que aparece en la parte superior del shell cuando portería
/// registra una entrada para el apartamento del copropietario (via Reverb).
/// Se auto-descarta a los 8 segundos y puede deslizarse hacia arriba para cerrar.
class AccessConfirmationBanner extends ConsumerStatefulWidget {
  const AccessConfirmationBanner({super.key});

  @override
  ConsumerState<AccessConfirmationBanner> createState() =>
      _AccessConfirmationBannerState();
}

class _AccessConfirmationBannerState
    extends ConsumerState<AccessConfirmationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  AccessEvent? _currentEvent;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AccessEvent?>(liveAccessProvider, (prev, next) {
      if (next != null) {
        setState(() => _currentEvent = next);
        _ctrl.forward(from: 0);
      } else {
        _ctrl.reverse().then((_) {
          if (mounted) setState(() => _currentEvent = null);
        });
      }
    });

    if (_currentEvent == null) return const SizedBox.shrink();

    return SlideTransition(
      position: _slide,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: _BannerCard(
            event: _currentEvent!,
            onDismiss: () => ref.read(liveAccessProvider.notifier).dismiss(),
          ),
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.event, required this.onDismiss});

  final AccessEvent event;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm', 'es');
    final entryTime = timeFmt.format(event.entryDateTime);

    return Dismissible(
      key: ValueKey(event.entryAt),
      direction: DismissDirection.up,
      onDismissed: (_) => onDismiss(),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onDismiss,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1B5E20),
                  const Color(0xFF2E7D32),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.meeting_room_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle,
                                    size: 7, color: Color(0xFF69F0AE)),
                                const SizedBox(width: 4),
                                Text(
                                  'Acceso registrado · $entryTime',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        event.visitorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.document != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${event.documentType ?? "Doc"}: ${event.document}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (event.registeredByName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Por: ${event.registeredByName}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
