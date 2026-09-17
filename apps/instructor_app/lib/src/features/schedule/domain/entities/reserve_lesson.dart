final class ReserveLesson {
  const ReserveLesson({
    required this.candidateId,
    required this.startAt,
    this.notes,
  });
  final String candidateId;
  final DateTime startAt;
  final String? notes;
}
