import '../../domain/entities/instructor_lesson.dart';
import '../../domain/entities/instructor_lesson_filters.dart';

enum ScheduleStatus { initial, loading, loaded, failure }

enum ScheduleRangeMode { day, week }

class ScheduleState {
  const ScheduleState({
    required this.status,
    required this.selectedDate,
    required this.rangeMode,
    required this.filters,
    this.lessons = const [],
    this.actionLessonId,
    this.successMessage,
    this.successEventId = 0,
    this.errorMessage,
    this.errorStatusCode,
    this.errorEventId = 0,
  });

  factory ScheduleState.initial() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return ScheduleState(
      status: ScheduleStatus.initial,
      selectedDate: today,
      rangeMode: ScheduleRangeMode.day,
      filters: InstructorLessonFilters(
        from: today,
        to: DateTime(today.year, today.month, today.day + 1),
      ),
    );
  }

  final ScheduleStatus status;
  final DateTime selectedDate;
  final ScheduleRangeMode rangeMode;
  final InstructorLessonFilters filters;
  final List<InstructorLesson> lessons;
  final String? actionLessonId;
  final String? successMessage;
  final int successEventId;
  final String? errorMessage;
  final int? errorStatusCode;
  final int errorEventId;

  bool get isLoading =>
      status == ScheduleStatus.initial || status == ScheduleStatus.loading;

  ScheduleState copyWith({
    ScheduleStatus? status,
    DateTime? selectedDate,
    ScheduleRangeMode? rangeMode,
    InstructorLessonFilters? filters,
    List<InstructorLesson>? lessons,
    String? actionLessonId,
    bool clearActionLessonId = false,
    String? successMessage,
    int? successEventId,
    String? errorMessage,
    int? errorStatusCode,
    int? errorEventId,
  }) {
    return ScheduleState(
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      rangeMode: rangeMode ?? this.rangeMode,
      filters: filters ?? this.filters,
      lessons: lessons ?? this.lessons,
      actionLessonId: clearActionLessonId
          ? null
          : actionLessonId ?? this.actionLessonId,
      successMessage: successMessage,
      successEventId: successEventId ?? this.successEventId,
      errorMessage: errorMessage,
      errorStatusCode: errorStatusCode,
      errorEventId: errorEventId ?? this.errorEventId,
    );
  }
}
