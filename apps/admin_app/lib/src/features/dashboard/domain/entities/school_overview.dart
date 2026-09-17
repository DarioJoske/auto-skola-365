final class SchoolOverview {
  SchoolOverview({
    required this.date,
    required this.timeZone,
    required this.activeCandidates,
    required this.unassignedActiveCandidates,
    required this.pendingRequests,
    required this.overdueLessons,
    required this.confirmedToday,
    required this.completedToday,
    required List<OverviewLesson> todayLessons,
    required List<OverviewLesson> requests,
    required List<OverviewLesson> overdue,
  }) : todayLessons = List.unmodifiable(todayLessons),
       requests = List.unmodifiable(requests),
       overdue = List.unmodifiable(overdue);
  final String date, timeZone;
  final int activeCandidates,
      unassignedActiveCandidates,
      pendingRequests,
      overdueLessons,
      confirmedToday,
      completedToday;
  final List<OverviewLesson> todayLessons, requests, overdue;
}

final class OverviewLesson {
  const OverviewLesson({
    required this.id,
    required this.candidateId,
    required this.candidateName,
    required this.instructorId,
    required this.instructorName,
    required this.categoryCode,
    required this.status,
    required this.startAt,
    required this.endAt,
  });
  final String id,
      candidateId,
      candidateName,
      instructorId,
      instructorName,
      categoryCode,
      status;
  // Preserve the server's school-local offset for display, independent of browser timezone.
  final String startAt, endAt;
  String get date => startAt.substring(0, 10);
  String get time => startAt.substring(11, 16);
}
