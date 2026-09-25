final class CandidateLesson {
  const CandidateLesson({
    required this.id,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.instructorName,
    this.branchName,
    this.proposedStartAt,
  });
  final String id, status, instructorName;
  final String? branchName;
  final DateTime startAt, endAt;
  final DateTime? proposedStartAt;
  DateTime get effectiveEnd =>
      proposedStartAt?.add(const Duration(hours: 1)) ?? endAt;
  bool get isScheduled => status == 'REQUESTED' || status == 'CONFIRMED';
  String get statusLabel => switch (status) {
    'REQUESTED' =>
      proposedStartAt == null ? 'Čeka potvrdu' : 'Predloženo drugo vrijeme',
    'CONFIRMED' => 'Potvrđeno',
    'COMPLETED' => 'Odrađeno',
    'CANCELLED' => 'Otkazano',
    'NO_SHOW' => 'Nedolazak',
    _ => status,
  };
}

final class CandidatePortal {
  CandidatePortal({
    required this.candidateId,
    required this.firstName,
    required this.lastName,
    required this.schoolName,
    required this.categoryCode,
    required this.instructorName,
    required this.canRequestLesson,
    required this.completedDrivingHours,
    required this.requiredDrivingHours,
    required List<CandidateLesson> lessons,
  }) : lessons = List.unmodifiable(lessons);
  final String candidateId, firstName, lastName, schoolName, categoryCode;
  final String? instructorName;
  final bool canRequestLesson;
  final int completedDrivingHours;
  final int? requiredDrivingHours;
  final List<CandidateLesson> lessons;
  List<CandidateLesson> upcomingAt(DateTime now) =>
      lessons
          .where((l) => l.isScheduled && l.effectiveEnd.isAfter(now))
          .toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
  List<CandidateLesson> historyAt(DateTime now) =>
      lessons
          .where((l) => !l.isScheduled || !l.effectiveEnd.isAfter(now))
          .toList()
        ..sort((a, b) => b.startAt.compareTo(a.startAt));
}
