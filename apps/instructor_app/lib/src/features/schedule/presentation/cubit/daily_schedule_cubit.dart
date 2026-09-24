import 'package:bloc/bloc.dart';
import '../../../../core/api/failure.dart';
import '../../../../core/api/result_extensions.dart';
import '../../domain/entities/instructor_lesson.dart';
import '../../domain/entities/instructor_lesson_filters.dart';
import '../../domain/usecases/list_instructor_lessons.dart';

final class DailyScheduleState {
  DailyScheduleState({
    required this.now,
    List<InstructorLesson> lessons = const [],
    this.loading = false,
    this.failure,
    this.eventId = 0,
  }) : lessons = List.unmodifiable(lessons);
  final DateTime now;
  final List<InstructorLesson> lessons;
  final bool loading;
  final Failure? failure;
  final int eventId;
  List<InstructorLesson> get today => List.unmodifiable(
    lessons.where((lesson) {
      final start = lesson.startAt.toLocal();
      return start.year == now.year &&
          start.month == now.month &&
          start.day == now.day;
    }),
  );
  List<InstructorLesson> get requests => List.unmodifiable(
    lessons.where((lesson) => lesson.status == 'REQUESTED'),
  );
  List<InstructorLesson> get upcoming => List.unmodifiable(
    lessons.where(
      (lesson) => lesson.status == 'CONFIRMED' && lesson.endAt.isAfter(now),
    ),
  );
  InstructorLesson? get nextLesson => upcoming.firstOrNull;
}

class DailyScheduleCubit extends Cubit<DailyScheduleState> {
  DailyScheduleCubit({
    required ListInstructorLessons listLessons,
    required String schoolId,
    required String accessToken,
    DateTime Function()? clock,
  }) : _listLessons = listLessons,
       _schoolId = schoolId,
       _accessToken = accessToken,
       _clock = clock ?? DateTime.now,
       super(DailyScheduleState(now: (clock ?? DateTime.now)()));
  final ListInstructorLessons _listLessons;
  final String _schoolId, _accessToken;
  final DateTime Function() _clock;
  int _request = 0;
  Future<void> load() async {
    if (isClosed) return;
    final request = ++_request;
    final now = _clock().toLocal();
    emit(
      DailyScheduleState(
        now: now,
        lessons: state.lessons,
        loading: true,
        eventId: state.eventId,
      ),
    );
    final result = await _listLessons(
      schoolId: _schoolId,
      accessToken: _accessToken,
      filters: InstructorLessonFilters(
        from: DateTime(now.year, now.month, now.day),
        to: DateTime(now.year, now.month, now.day + 7),
      ),
    );
    if (isClosed || request != _request) return;
    result.resolveWithFailure(
      onFailure: (failure) => emit(
        DailyScheduleState(
          now: now,
          lessons: [401, 403].contains(failure.statusCode)
              ? const []
              : state.lessons,
          failure: failure,
          eventId: state.eventId + 1,
        ),
      ),
      onSuccess: (lessons) {
        final sorted = [...lessons]
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
        emit(
          DailyScheduleState(now: now, lessons: sorted, eventId: state.eventId),
        );
      },
    );
  }
}
