final class InstructorOverview {
  InstructorOverview({
    required this.weekStart,
    required this.weekEnd,
    required this.timeZone,
    required List<InstructorSummary> instructors,
  }) : instructors = List.unmodifiable(instructors);
  final String weekStart, weekEnd, timeZone;
  final List<InstructorSummary> instructors;
}

final class InstructorSummary {
  InstructorSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.active,
    required List<String> categoryCodes,
    required this.confirmedLessons,
    required this.confirmedMinutes,
    required List<AssignedCandidate> candidates,
  }) : categoryCodes = List.unmodifiable(categoryCodes),
       candidates = List.unmodifiable(candidates);
  final String id, name, email;
  final bool active;
  final List<String> categoryCodes;
  final int confirmedLessons, confirmedMinutes;
  final List<AssignedCandidate> candidates;
}

final class AssignedCandidate {
  const AssignedCandidate({
    required this.id,
    required this.name,
    required this.status,
    required this.categoryCode,
  });
  final String id, name, status, categoryCode;
}
