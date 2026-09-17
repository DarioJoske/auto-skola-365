import '../../domain/entities/reserve_lesson.dart';

final class ReserveLessonModel {
  const ReserveLessonModel(this.reservation);
  final ReserveLesson reservation;
  Map<String, dynamic> toJson() => {
    'candidateId': reservation.candidateId,
    'startAt': reservation.startAt.toUtc().toIso8601String(),
    'notes': reservation.notes,
  };
}
