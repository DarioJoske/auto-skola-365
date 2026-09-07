import '../../domain/entities/current_user.dart';
import '../../domain/entities/membership.dart';

class CurrentUserModel {
  const CurrentUserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.status,
    required this.memberships,
  });

  factory CurrentUserModel.fromJson(Map<String, dynamic> json) {
    return CurrentUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      status: json['status'] as String,
      memberships: (json['memberships'] as List<dynamic>? ?? [])
          .map((item) => MembershipModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String status;
  final List<MembershipModel> memberships;

  CurrentUser toEntity() {
    return CurrentUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      status: status,
      memberships: memberships
          .map((membership) => membership.toEntity())
          .toList(),
    );
  }
}

class MembershipModel {
  const MembershipModel({
    required this.id,
    required this.schoolId,
    required this.schoolName,
    required this.membershipStatus,
    required this.roleKey,
    required this.roleName,
    required this.roleScope,
    required this.permissions,
  });

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    return MembershipModel(
      id: json['id'] as String,
      schoolId: json['schoolId'] as String,
      schoolName: json['schoolName'] as String,
      membershipStatus: json['membershipStatus'] as String,
      roleKey: json['roleKey'] as String,
      roleName: json['roleName'] as String,
      roleScope: json['roleScope'] as String,
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((permission) => permission as String)
          .toList(),
    );
  }

  final String id;
  final String schoolId;
  final String schoolName;
  final String membershipStatus;
  final String roleKey;
  final String roleName;
  final String roleScope;
  final List<String> permissions;

  Membership toEntity() {
    return Membership(
      id: id,
      schoolId: schoolId,
      schoolName: schoolName,
      membershipStatus: membershipStatus,
      roleKey: roleKey,
      roleName: roleName,
      roleScope: roleScope,
      permissions: permissions,
    );
  }
}
