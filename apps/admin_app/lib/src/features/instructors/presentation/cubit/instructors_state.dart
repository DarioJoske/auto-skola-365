import '../../domain/entities/instructor.dart';
import '../../domain/entities/instructor_filters.dart';

enum InstructorsStatus { initial, loading, loaded, failure }

class InstructorsState {
  const InstructorsState({
    required this.status,
    this.instructors = const [],
    this.filters = const InstructorFilters(),
    this.errorMessage,
    this.errorStatusCode,
    this.isSubmitting = false,
  });

  const InstructorsState.initial() : this(status: InstructorsStatus.initial);

  final InstructorsStatus status;
  final List<Instructor> instructors;
  final InstructorFilters filters;
  final String? errorMessage;
  final int? errorStatusCode;
  final bool isSubmitting;

  InstructorsState copyWith({
    InstructorsStatus? status,
    List<Instructor>? instructors,
    InstructorFilters? filters,
    String? errorMessage,
    int? errorStatusCode,
    bool? isSubmitting,
  }) {
    return InstructorsState(
      status: status ?? this.status,
      instructors: instructors ?? this.instructors,
      filters: filters ?? this.filters,
      errorMessage: errorMessage,
      errorStatusCode: errorStatusCode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
