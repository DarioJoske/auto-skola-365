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
  });
  final CandidatePortal? data;
  final bool loading, saving;
  final Failure? loadFailure, actionFailure;
  final int errorId, savedId;
}
