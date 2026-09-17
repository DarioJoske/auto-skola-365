import 'package:auto_skola_365_candidate_app/src/app/app_dependencies.dart';
import 'package:auto_skola_365_candidate_app/src/app/candidate_app.dart';
import 'package:auto_skola_365_candidate_app/src/core/api/result.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/domain/entities/auth_session.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/domain/usecases/bootstrap_auth_session.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/domain/usecases/login.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/domain/usecases/logout.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/domain/usecases/load_portal.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/domain/usecases/request_lesson.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_test.dart' show Remote;
import 'portal_test.dart' show PortalFake;

class SessionRepository extends Fake implements AuthRepository {
  SessionRepository(this.session);
  final AuthSession session;
  @override
  FutureEither<AuthSession?> bootstrapSession() async => const Right(null);
  @override
  FutureEither<AuthSession> login({
    required String email,
    required String password,
  }) async => Right(session);
  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets(
    'tabs switch immediately without overlapping pages',
    (tester) async {
      final user = (await Remote().login(
        email: 'ana@example.com',
        password: 'Password123!',
      )).user.toEntity();
      final repository = SessionRepository(
        AuthSession(
          accessToken: 'token',
          user: user,
          candidateMembership: user.candidateMembership!,
        ),
      );
      final auth = AuthCubit(
        bootstrapAuthSession: BootstrapAuthSession(repository),
        login: Login(repository),
        logout: Logout(repository),
      );
      final portal = PortalFake();
      var loadCount = 0;
      portal.onLoad = () async {
        loadCount++;
        return Right(portal.value);
      };
      getIt.registerSingleton<AuthCubit>(auth);
      getIt.registerSingleton<LoadPortal>(LoadPortal(portal));
      getIt.registerSingleton<RequestLesson>(RequestLesson(portal));
      addTearDown(() async {
        await getIt.reset();
        await auth.close();
      });
      await tester.pumpWidget(const CandidateApp());
      await tester.pumpAndSettle();
      expect(find.text('Prijavi se'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'ana@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Lozinka'),
        'Password123!',
      );
      await tester.tap(find.text('Prijavi se'));
      await tester.pumpAndSettle();
      expect(find.text('Bok, Ana.'), findsOneWidget);
      final navigation = tester.element(find.byType(NavigationBar));
      await tester.tap(find.text('Termini'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Tvoji termini'), findsOneWidget);
      expect(find.text('Bok, Ana.'), findsNothing);
      expect(tester.element(find.byType(NavigationBar)), same(navigation));
      expect(loadCount, 1);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Povijest'));
      await tester.pumpAndSettle();
      expect(find.text('Odrađeno'), findsOneWidget);
      await tester.tap(find.text('Moj profil'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Tvoji termini'), findsNothing);
      expect(find.text('ana@example.com'), findsOneWidget);
      // Rapid tab changes must leave only the selected destination visible.
      await tester.tap(find.text('Pregled'));
      await tester.pump();
      await tester.tap(find.text('Termini'));
      await tester.pump();
      await tester.tap(find.text('Moj profil'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Bok, Ana.'), findsNothing);
      expect(find.text('Tvoji termini'), findsNothing);
      expect(loadCount, 1);
      await tester.pumpAndSettle();
      expect(find.text('ana@example.com'), findsOneWidget);
      await tester.tap(find.byTooltip('Odjavi se'));
      await tester.pumpAndSettle();
      expect(find.text('Prijavi se'), findsOneWidget);
      expect(find.text('ana@example.com'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );
}
