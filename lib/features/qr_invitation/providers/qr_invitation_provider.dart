import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_utils.dart';
import '../data/qr_invitation_repository.dart';
import '../models/visit_qr_code.dart';

class QrInvitationState {
  const QrInvitationState({
    this.qrCodes = const [],
    this.selectedStatus,
    this.isLoading = false,
    this.isCreating = false,
    this.error,
  });

  final List<VisitQrCode> qrCodes;
  final String? selectedStatus;
  final bool isLoading;
  final bool isCreating;
  final String? error;

  QrInvitationState copyWith({
    List<VisitQrCode>? qrCodes,
    String? selectedStatus,
    bool? isLoading,
    bool? isCreating,
    String? error,
    bool clearError = false,
    bool clearStatus = false,
  }) {
    return QrInvitationState(
      qrCodes: qrCodes ?? this.qrCodes,
      selectedStatus:
          clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class QrInvitationNotifier extends Notifier<QrInvitationState> {
  @override
  QrInvitationState build() {
    Future.microtask(_loadHistory);
    return const QrInvitationState(isLoading: true);
  }

  Future<void> _loadHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final qrCodes = await ref
          .read(qrInvitationRepositoryProvider)
          .getHistory(estado: state.selectedStatus);
      state = state.copyWith(qrCodes: qrCodes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> setFilter(String? status) async {
    if (state.selectedStatus == status) return;
    state = state.copyWith(
      selectedStatus: status,
      clearStatus: status == null,
      isLoading: true,
      clearError: true,
    );
    try {
      final qrCodes = await ref
          .read(qrInvitationRepositoryProvider)
          .getHistory(estado: status);
      state = state.copyWith(qrCodes: qrCodes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<VisitQrCode?> create({
    required int apartmentId,
    required String visitorName,
    required String documentType,
    required String documentNumber,
    required String validFrom,
    required String validUntil,
    String? vehiclePlate,
  }) async {
    state = state.copyWith(isCreating: true, clearError: true);
    try {
      final created = await ref.read(qrInvitationRepositoryProvider).create(
            apartmentId: apartmentId,
            visitorName: visitorName,
            documentType: documentType,
            documentNumber: documentNumber,
            validFrom: validFrom,
            validUntil: validUntil,
            vehiclePlate: vehiclePlate,
          );
      // Prepend to list (newest first)
      state = state.copyWith(
        qrCodes: [created, ...state.qrCodes],
        isCreating: false,
      );
      return created;
    } catch (e) {
      state = state.copyWith(isCreating: false, error: _parseError(e));
      return null;
    }
  }

  Future<bool> revoke(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(qrInvitationRepositoryProvider).revoke(id);
      final updated = state.qrCodes.map((qr) {
        if (qr.id == id) {
          return VisitQrCode(
            id: qr.id,
            uuid: qr.uuid,
            qrUrl: qr.qrUrl,
            visitante: qr.visitante,
            apartamentoId: qr.apartamentoId,
            validoDesde: qr.validoDesde,
            validoHasta: qr.validoHasta,
            estado: 'revocado',
            createdAt: qr.createdAt,
            usadoEn: qr.usadoEn,
            revocadoEn: DateTime.now().toIso8601String(),
            visitaId: qr.visitaId,
          );
        }
        return qr;
      }).toList();
      state = state.copyWith(qrCodes: updated, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<void> refresh() => _loadHistory();

  String _parseError(Object e) => dioErrorMessage(e, 'No se pudo completar la solicitud.');
}

final qrInvitationProvider =
    NotifierProvider<QrInvitationNotifier, QrInvitationState>(
  QrInvitationNotifier.new,
);
