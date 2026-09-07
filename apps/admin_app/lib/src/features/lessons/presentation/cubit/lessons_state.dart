import '../../../candidates/domain/entities/candidate.dart';
import '../../../instructors/domain/entities/instructor.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_filters.dart';

enum LessonsStatus { initial, loading, loaded, failure }

class LessonsState {
  const LessonsState({
    required this.status,
    required this.filters,
    this.lessons = const [],
    this.candidates = const [],
    this.instructors = const [],
    this.errorMessage,
    this.errorStatusCode,
    this.errorEventId = 0,
    this.isSubmitting = false,
  });

  LessonsState.initial()
    : this(
        status: LessonsStatus.initial,
        filters: LessonFilters(
          from: _startOfWeek(DateTime.now()),
          to: _startOfWeek(DateTime.now()).add(const Duration(days: 7)),
        ),
      );

  final LessonsStatus status;
  final LessonFilters filters;
  final List<Lesson> lessons;
  final List<Candidate> candidates;
  final List<Instructor> instructors;
  final String? errorMessage;
  final int? errorStatusCode;
  final int errorEventId;
  final bool isSubmitting;

  LessonsState copyWith({
    LessonsStatus? status,
    LessonFilters? filters,
    List<Lesson>? lessons,
    List<Candidate>? candidates,
    List<Instructor>? instructors,
    String? errorMessage,
    int? errorStatusCode,
    int? errorEventId,
    bool? isSubmitting,
  }) {
    return LessonsState(
      status: status ?? this.status,
      filters: filters ?? this.filters,
      lessons: lessons ?? this.lessons,
      candidates: candidates ?? this.candidates,
      instructors: instructors ?? this.instructors,
      errorMessage: errorMessage,
      errorStatusCode: errorStatusCode,
      errorEventId: errorEventId ?? this.errorEventId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  static DateTime _startOfWeek(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }
}
