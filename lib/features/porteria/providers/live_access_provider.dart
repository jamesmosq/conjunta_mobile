import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/access_event.dart';

final liveAccessProvider =
    StateNotifierProvider<LiveAccessNotifier, AccessEvent?>(
  (_) => LiveAccessNotifier(),
);

class LiveAccessNotifier extends StateNotifier<AccessEvent?> {
  LiveAccessNotifier() : super(null);

  Timer? _clearTimer;

  static const _autoClearDuration = Duration(seconds: 8);

  void notify(AccessEvent event) {
    _clearTimer?.cancel();
    state = event;
    _clearTimer = Timer(_autoClearDuration, dismiss);
  }

  void dismiss() {
    _clearTimer?.cancel();
    _clearTimer = null;
    state = null;
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }
}
