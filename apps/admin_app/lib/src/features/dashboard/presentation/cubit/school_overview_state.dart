import '../../../../core/api/failure.dart';
import '../../domain/entities/school_overview.dart';

final class SchoolOverviewState {
  const SchoolOverviewState({
    this.data,
    this.isLoading = false,
    this.failure,
    this.errorEventId = 0,
  });
  final SchoolOverview? data;
  final bool isLoading;
  final Failure? failure;
  final int errorEventId;
}
