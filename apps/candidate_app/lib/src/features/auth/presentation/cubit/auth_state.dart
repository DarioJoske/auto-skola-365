import '../../domain/entities/current_user.dart';
import '../../domain/entities/membership.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.candidateMembership,
    this.accessToken,
    this.errorMessage,
  });

  const AuthState.initial() : this(status: AuthStatus.initial);
  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  const AuthState.authenticated({
    required CurrentUser user,
    required Membership candidateMembership,
    required String accessToken,
  }) : this(
         status: AuthStatus.authenticated,
         user: user,
         candidateMembership: candidateMembership,
         accessToken: accessToken,
       );

  const AuthState.failure(String message)
    : this(status: AuthStatus.failure, errorMessage: message);

  final AuthStatus status;
  final CurrentUser? user;
  final Membership? candidateMembership;
  final String? accessToken;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}
