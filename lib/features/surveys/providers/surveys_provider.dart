import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/surveys_repository.dart';
import '../models/survey.dart';

// ── State ──────────────────────────────────────────────────────────────────────

class SurveysState {
  const SurveysState({
    this.surveys = const [],
    this.isLoading = false,
    this.error,
    this.respondedIds = const {},
  });

  final List<Survey> surveys;
  final bool isLoading;
  final String? error;

  /// IDs respondidos en esta sesión (sin cambiar el backend hasta confirmar).
  final Set<int> respondedIds;

  List<Survey> get activePending => surveys
      .where((s) => s.isActive && !respondedIds.contains(s.id))
      .toList();

  int get pendingCount => activePending.length;

  SurveysState copyWith({
    List<Survey>? surveys,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Set<int>? respondedIds,
  }) =>
      SurveysState(
        surveys: surveys ?? this.surveys,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        respondedIds: respondedIds ?? this.respondedIds,
      );
}

// ── Provider ───────────────────────────────────────────────────────────────────

final surveysProvider =
    StateNotifierProvider<SurveysNotifier, SurveysState>(
  (ref) => SurveysNotifier(ref)..load(),
);

final pendingSurveysCountProvider = Provider<int>((ref) {
  return ref.watch(surveysProvider).pendingCount;
});

// Survey detail — cargado bajo demanda en la pantalla de respuesta
final surveyDetailProvider = FutureProvider.autoDispose.family<Survey, int>(
  (ref, id) => ref.read(surveysRepositoryProvider).getSurvey(id),
);

// ── Notifier ───────────────────────────────────────────────────────────────────

class SurveysNotifier extends StateNotifier<SurveysState> {
  SurveysNotifier(this._ref) : super(const SurveysState());

  final Ref _ref;

  SurveysRepository get _repo => _ref.read(surveysRepositoryProvider);

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.getSurveys(status: 'active');
      // El provider puede haber sido invalidado (ej. resetUserScopedProviders
      // en login/logout) mientras esta llamada estaba en curso — escribir en
      // `state` de un notifier ya disposed lanza "Bad state: ... after
      // dispose was called".
      if (!mounted) return;
      state = state.copyWith(surveys: items, isLoading: false);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudieron cargar las encuestas.',
      );
    }
  }

  Future<void> refresh() async {
    state = SurveysState(respondedIds: state.respondedIds);
    await load();
  }

  /// Envía las respuestas al backend y marca localmente como respondida.
  /// Lanza excepción si el servidor rechaza (409 ya respondida, etc.).
  Future<void> respond(
    int surveyId,
    List<Map<String, dynamic>> answers,
  ) async {
    try {
      await _repo.respond(surveyId, answers);
    } on DioException catch (e) {
      // 409 = ya respondió en otro dispositivo — aceptamos y marcamos local
      if (e.response?.statusCode == 409) {
        _markResponded(surveyId);
        rethrow;
      }
      rethrow;
    }
    _markResponded(surveyId);
  }

  void _markResponded(int surveyId) {
    state = state.copyWith(
      respondedIds: {...state.respondedIds, surveyId},
    );
  }
}
