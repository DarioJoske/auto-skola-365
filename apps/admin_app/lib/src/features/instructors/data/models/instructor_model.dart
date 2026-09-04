import '../../domain/entities/instructor.dart';

class InstructorModel {
  const InstructorModel({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.membershipId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.active,
    required this.categoryCodes,
    required this.availabilityRules,
  });

  factory InstructorModel.fromJson(Map<String, dynamic> json) {
    return InstructorModel(
      id: json['id'] as String,
      schoolId: json['schoolId'] as String,
      userId: json['userId'] as String,
      membershipId: json['membershipId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      active: json['active'] as bool,
      categoryCodes: List<String>.from(json['categoryCodes'] as List<dynamic>),
      availabilityRules: (json['availabilityRules'] as List<dynamic>)
          .map(
            (item) => InstructorAvailabilityRuleModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final String id;
  final String schoolId;
  final String userId;
  final String membershipId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? licenseNumber;
  final bool active;
  final List<String> categoryCodes;
  final List<InstructorAvailabilityRuleModel> availabilityRules;

  Instructor toEntity() {
    return Instructor(
      id: id,
      schoolId: schoolId,
      userId: userId,
      membershipId: membershipId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      licenseNumber: licenseNumber,
      active: active,
      categoryCodes: categoryCodes,
      availabilityRules: availabilityRules
          .map((rule) => rule.toEntity())
          .toList(),
    );
  }
}

class InstructorAvailabilityRuleModel {
  const InstructorAvailabilityRuleModel({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory InstructorAvailabilityRuleModel.fromJson(Map<String, dynamic> json) {
    return InstructorAvailabilityRuleModel(
      id: json['id'] as String?,
      dayOfWeek: json['dayOfWeek'] as int,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
    );
  }

  final String? id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  InstructorAvailabilityRule toEntity() {
    return InstructorAvailabilityRule(
      id: id,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
    );
  }
}
