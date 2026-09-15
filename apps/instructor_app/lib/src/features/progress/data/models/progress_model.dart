import '../../domain/entities/candidate_progress.dart';

class ProgressModel {
  const ProgressModel(this._json);
  factory ProgressModel.fromJson(Map<String, dynamic> json) =>
      ProgressModel(Map.unmodifiable(json));
  final Map<String, dynamic> _json;
  Map<String, dynamic> toJson() => Map.of(_json);
  CandidateProgress toEntity() => CandidateProgress(
    candidateName: _json['candidateName'] as String,
    categoryCode: _json['categoryCode'] as String,
    lessonId: _json['lessonId'] as String?,
    editable: _json['editable'] as bool,
    skills: _options(_json['skills']),
    statuses: _options(_json['statuses']),
    entries: (_json['entries'] as List<dynamic>).map((raw) {
      final j = raw as Map<String, dynamic>;
      return ProgressEntry(
        lessonId: j['lessonId'] as String,
        lessonEndAt: DateTime.parse(j['lessonEndAt'] as String).toLocal(),
        skill: j['skill'] as String,
        status: j['status'] as String,
        recordedAt: DateTime.parse(j['recordedAt'] as String).toLocal(),
      );
    }).toList(),
  );
  List<ProgressOption> _options(dynamic raw) =>
      (raw as List<dynamic>).map((item) {
        final j = item as Map<String, dynamic>;
        return ProgressOption(j['code'] as String, j['label'] as String);
      }).toList();
}
