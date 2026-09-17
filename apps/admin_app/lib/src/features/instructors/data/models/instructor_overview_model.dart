import '../../domain/entities/instructor_overview.dart';

final class InstructorOverviewModel {
  InstructorOverviewModel.fromJson(Map<String, dynamic> json)
    : entity = InstructorOverview(
        weekStart: json['weekStart'] as String,
        weekEnd: json['weekEnd'] as String,
        timeZone: json['timeZone'] as String,
        instructors: (json['instructors'] as List<dynamic>).map((item) {
          final row = item as Map<String, dynamic>;
          return InstructorSummary(
            id: row['id'] as String,
            name: row['name'] as String,
            email: row['email'] as String,
            active: row['active'] as bool,
            categoryCodes: (row['categoryCodes'] as List<dynamic>)
                .cast<String>(),
            confirmedLessons: row['confirmedLessons'] as int,
            confirmedMinutes: row['confirmedMinutes'] as int,
            candidates: (row['candidates'] as List<dynamic>).map((item) {
              final candidate = item as Map<String, dynamic>;
              return AssignedCandidate(
                id: candidate['id'] as String,
                name: candidate['name'] as String,
                status: candidate['status'] as String,
                categoryCode: candidate['categoryCode'] as String,
              );
            }).toList(),
          );
        }).toList(),
      );
  final InstructorOverview entity;
}
