import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

enum ForgotPasswordStatus { idle, loading, sent, error }

class ForgotPasswordState {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.idle,
    this.errorMessage,
  });

  final ForgotPasswordStatus status;
  final String? errorMessage;

  bool get isLoading => status == ForgotPasswordStatus.loading;
  bool get isSent => status == ForgotPasswordStatus.sent;
  bool get hasError => status == ForgotPasswordStatus.error;

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? errorMessage,
  }) =>
      ForgotPasswordState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class ForgotPasswordNotifier extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  Future<void> sendResetLink(String email) async {
    state = state.copyWith(status: ForgotPasswordStatus.loading, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email.trim());
      state = state.copyWith(status: ForgotPasswordStatus.sent);
    } catch (_) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: 'No pudimos enviar el correo. Verifica la dirección e intenta de nuevo.',
      );
    }
  }

  void reset() => state = const ForgotPasswordState();
}

final forgotPasswordProvider =
    NotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(
  ForgotPasswordNotifier.new,
);
