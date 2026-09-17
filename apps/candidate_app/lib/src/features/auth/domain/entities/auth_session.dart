import 'current_user.dart';
import 'membership.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.user,
    required this.candidateMembership,
  });

  final String accessToken;
  final CurrentUser user;
  final Membership candidateMembership;
}
