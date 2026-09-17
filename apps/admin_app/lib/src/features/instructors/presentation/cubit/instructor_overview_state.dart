import '../../../../core/api/failure.dart';
import '../../domain/entities/instructor_overview.dart';

final class InstructorOverviewState {
  const InstructorOverviewState({
    this.data,
    this.isLoading = false,
    this.failure,
    this.errorEventId = 0,
    this.query = '',
    this.active,
  });
  final InstructorOverview? data;
  final bool isLoading;
  final Failure? failure;
  final int errorEventId;
  final String query;
  final bool? active;
}
