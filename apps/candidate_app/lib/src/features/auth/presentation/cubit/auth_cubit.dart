import 'package:bloc/bloc.dart';

import '../../../../core/api/result_extensions.dart';
import '../../domain/usecases/bootstrap_auth_session.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required BootstrapAuthSession bootstrapAuthSession,
    required Login login,
    required Logout logout,
  }) : _bootstrapAuthSession = bootstrapAuthSession,
       _login = login,
       _logout = logout,
       super(const AuthState.initial());

  final BootstrapAuthSession _bootstrapAuthSession;
  final Login _login;
  final Logout _logout;

  Future<void> bootstrap() async {
    if (isClosed || state.status == AuthStatus.loading) return;
    emit(const AuthState.loading());

    final result = await _bootstrapAuthSession();
    if (isClosed) return;
    result.resolve(
      onFailure: (message) => emit(AuthState.failure(message)),
      onSuccess: (session) {
        if (session == null) {
          emit(const AuthState.unauthenticated());
          return;
        }

        emit(
          AuthState.authenticated(
            user: session.user,
            candidateMembership: session.candidateMembership,
            accessToken: session.accessToken,
          ),
        );
      },
    );
  }

  Future<void> login({required String email, required String password}) async {
    if (isClosed || state.status == AuthStatus.loading) return;
    emit(const AuthState.loading());

    final result = await _login(email: email, password: password);
    if (isClosed) return;
    result.resolve(
      onFailure: (message) => emit(AuthState.failure(message)),
      onSuccess: (session) => emit(
        AuthState.authenticated(
          user: session.user,
          candidateMembership: session.candidateMembership,
          accessToken: session.accessToken,
        ),
      ),
    );
  }

  Future<void> logout() async {
    await _logout();
    if (!isClosed) emit(const AuthState.unauthenticated());
  }
}
