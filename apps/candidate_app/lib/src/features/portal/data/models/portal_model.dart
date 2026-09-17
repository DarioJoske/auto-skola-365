import '../../domain/entities/candidate_portal.dart';

final class PortalModel {
  PortalModel.fromJson(Map<String, dynamic> json)
    : _json = Map.unmodifiable(json);
  final Map<String, dynamic> _json;
  Map<String, dynamic> toJson() => Map.of(_json);
  CandidatePortal toEntity() => CandidatePortal(
    candidateId: _json['candidateId'] as String,
    firstName: _json['firstName'] as String,
    lastName: _json['lastName'] as String,
    schoolName: _json['schoolName'] as String,
    categoryCode: _json['categoryCode'] as String,
    instructorName: _json['instructorName'] as String?,
    canRequestLesson: _json['canRequestLesson'] as bool,
    completedDrivingHours: _json['completedDrivingHours'] as int,
    requiredDrivingHours: _json['requiredDrivingHours'] as int?,
    lessons: (_json['lessons'] as List<dynamic>).map((item) {
      final j = item as Map<String, dynamic>;
      return CandidateLesson(
        id: j['id'] as String,
        status: j['status'] as String,
        startAt: DateTime.parse(j['startAt'] as String).toLocal(),
        endAt: DateTime.parse(j['endAt'] as String).toLocal(),
        instructorName: j['instructorName'] as String,
        branchName: j['branchName'] as String?,
      );
    }).toList(),
  );
}
