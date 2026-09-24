import '../../domain/entities/instructor_lesson.dart';

enum LessonDetailStatus { initial, loading, loaded, failure }

class LessonDetailState {
  const LessonDetailState({
    required this.status,
    this.lesson,
    this.actionInProgress = false,
    this.successMessage,
    this.successEventId = 0,
    this.errorMessage,
    this.errorStatusCode,
    this.errorEventId = 0,
  });

  factory LessonDetailState.initial() {
    return const LessonDetailState(status: LessonDetailStatus.initial);
  }

  final LessonDetailStatus status;
  final InstructorLesson? lesson;
  final bool actionInProgress;
  final String? successMessage;
  final int successEventId;
  final String? errorMessage;
  final int? errorStatusCode;
  final int errorEventId;

  bool get isLoading =>
      status == LessonDetailStatus.initial ||
      status == LessonDetailStatus.loading;

  LessonDetailState copyWith({
    LessonDetailStatus? status,
    InstructorLesson? lesson,
    bool clearLesson = false,
    bool? actionInProgress,
    String? successMessage,
    int? successEventId,
    String? errorMessage,
    int? errorStatusCode,
    int? errorEventId,
  }) {
    return LessonDetailState(
      status: status ?? this.status,
      lesson: clearLesson ? null : lesson ?? this.lesson,
      actionInProgress: actionInProgress ?? this.actionInProgress,
      successMessage: successMessage,
      successEventId: successEventId ?? this.successEventId,
      errorMessage: errorMessage,
      errorStatusCode: errorStatusCode,
      errorEventId: errorEventId ?? this.errorEventId,
    );
  }
}
