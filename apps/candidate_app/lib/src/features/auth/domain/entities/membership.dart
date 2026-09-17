class Membership {
  const Membership({
    required this.id,
    required this.schoolId,
    required this.schoolName,
    required this.membershipStatus,
    required this.roleKey,
    required this.roleName,
    required this.roleScope,
    required this.permissions,
  });

  final String id;
  final String schoolId;
  final String schoolName;
  final String membershipStatus;
  final String roleKey;
  final String roleName;
  final String roleScope;
  final List<String> permissions;

  bool get hasCandidateAccess {
    return membershipStatus == 'ACTIVE' &&
        (roleKey == 'candidate' || permissions.contains('lessons.reserve_own'));
  }
}
