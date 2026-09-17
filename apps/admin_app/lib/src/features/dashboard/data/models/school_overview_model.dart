import '../../domain/entities/school_overview.dart';

final class SchoolOverviewModel {
  SchoolOverviewModel.fromJson(Map<String, dynamic> json)
    : entity = SchoolOverview(
        date: json['date'] as String,
        timeZone: json['timeZone'] as String,
        activeCandidates: json['activeCandidates'] as int,
        unassignedActiveCandidates: json['unassignedActiveCandidates'] as int,
        pendingRequests: json['pendingRequests'] as int,
        overdueLessons: json['overdueLessons'] as int,
        confirmedToday: json['confirmedToday'] as int,
        completedToday: json['completedToday'] as int,
        todayLessons: _lessons(json['todayLessons']),
        requests: _lessons(json['requests']),
        overdue: _lessons(json['overdue']),
      );
  final SchoolOverview entity;
  static List<OverviewLesson> _lessons(dynamic value) =>
      (value as List<dynamic>).map((item) {
        final json = item as Map<String, dynamic>;
        return OverviewLesson(
          id: json['id'] as String,
          candidateId: json['candidateId'] as String,
          candidateName: json['candidateName'] as String,
          instructorId: json['instructorId'] as String,
          instructorName: json['instructorName'] as String,
          categoryCode: json['categoryCode'] as String,
          status: json['status'] as String,
          startAt: json['startAt'] as String,
          endAt: json['endAt'] as String,
        );
      }).toList();
}
