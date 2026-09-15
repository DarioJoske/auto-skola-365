class ProgressOption {
  const ProgressOption(this.code, this.label);
  final String code;
  final String label;
}

class ProgressEntry {
  const ProgressEntry({
    required this.lessonId,
    required this.lessonEndAt,
    required this.skill,
    required this.status,
    required this.recordedAt,
  });
  final String lessonId;
  final DateTime lessonEndAt;
  final String skill;
  final String status;
  final DateTime recordedAt;
}

class CandidateProgress {
  CandidateProgress({
    required this.candidateName,
    required this.categoryCode,
    required this.lessonId,
    required this.editable,
    required List<ProgressOption> skills,
    required List<ProgressOption> statuses,
    required List<ProgressEntry> entries,
  }) : skills = List.unmodifiable(skills),
       statuses = List.unmodifiable(statuses),
       entries = List.unmodifiable(entries);
  final String candidateName;
  final String categoryCode;
  final String? lessonId;
  final bool editable;
  final List<ProgressOption> skills;
  final List<ProgressOption> statuses;
  final List<ProgressEntry> entries;
  ProgressEntry? latest(String skill) {
    final matches = entries.where((e) => e.skill == skill).toList()
      ..sort((a, b) {
        final date = b.lessonEndAt.compareTo(a.lessonEndAt);
        return date != 0 ? date : b.recordedAt.compareTo(a.recordedAt);
      });
    return matches.isEmpty ? null : matches.first;
  }

  Map<String, String> get lessonAssessments => {
    for (final e in entries)
      if (e.lessonId == lessonId) e.skill: e.status,
  };
  String statusLabel(String code) => statuses
      .firstWhere(
        (s) => s.code == code,
        orElse: () => ProgressOption(code, code),
      )
      .label;
  String skillLabel(String code) => skills
      .firstWhere(
        (s) => s.code == code,
        orElse: () => ProgressOption(code, code),
      )
      .label;
}
