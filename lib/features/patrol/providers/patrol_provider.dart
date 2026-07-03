import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/patrol_repository.dart';
import '../models/patrol_route.dart';
import '../models/patrol_session.dart';

// ── Routes list ──────────────────────────────────────────────────────────────

final patrolRoutesProvider = FutureProvider.autoDispose<List<PatrolRoute>>((ref) {
  return ref.read(patrolRepositoryProvider).getRoutes();
});

// ── Active session state ──────────────────────────────────────────────────────

class PatrolState {
  const PatrolState({
    this.session,
    this.isLoading = false,
    this.error,
  });

  final PatrolSession? session;
  final bool isLoading;
  final String? error;

  PatrolState copyWith({
    PatrolSession? session,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PatrolState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PatrolNotifier extends StateNotifier<PatrolState> {
  PatrolNotifier(this._repo) : super(const PatrolState());

  final PatrolRepository _repo;

  Future<bool> startSession(int routeId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _repo.startSession(routeId);
      state = PatrolState(session: session);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<void> loadSession(int sessionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _repo.getSession(sessionId);
      state = PatrolState(session: session);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<bool> scanCheckpoint({
    required String uuid,
    required String token,
    int? checkpointId,
    String? notes,
  }) async {
    final current = state.session;
    if (current == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.scanCheckpoint(
        sessionId: current.id,
        uuid: uuid,
        token: token,
        notes: notes,
      );
      if (checkpointId != null) {
        final updatedIds = [...current.scannedCheckpointIds, checkpointId];
        state = PatrolState(
          session: current.copyWith(
            checkpointsScanned: current.checkpointsScanned + 1,
            scannedCheckpointIds: updatedIds,
          ),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> reportIncident({
    required String description,
    required String severity,
    int? checkpointId,
    File? photo,
  }) async {
    final current = state.session;
    if (current == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.reportIncident(
        sessionId: current.id,
        description: description,
        severity: severity,
        checkpointId: checkpointId,
        photo: photo,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<PatrolSession?> finishSession({String? notes}) async {
    final current = state.session;
    if (current == null) return null;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final finished = await _repo.finishSession(current.id, notes: notes);
      state = PatrolState(session: finished);
      return finished;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return null;
    }
  }

  void clearSession() => state = const PatrolState();

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) return msg.substring(11);
    return msg;
  }
}

final patrolProvider = StateNotifierProvider<PatrolNotifier, PatrolState>((ref) {
  return PatrolNotifier(ref.read(patrolRepositoryProvider));
});
