import '../../../../core/api/failure.dart';
import '../../domain/entities/candidate_portal.dart';

final class PortalState {
  const PortalState({
    this.data,
    this.loading = false,
    this.saving = false,
    this.loadFailure,
    this.actionFailure,
    this.errorId = 0,
    this.savedId = 0,
    this.responseId = 0,
    this.lastRequestedStart,
  });
  final CandidatePortal? data;
  final bool loading, saving;
  final Failure? loadFailure, actionFailure;
  final int errorId, savedId, responseId;
  final DateTime? lastRequestedStart;
}
