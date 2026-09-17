import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:auto_skola_design_system/design_system.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import 'app_dependencies.dart';
import 'router/app_router.dart';
import 'router/go_router_refresh_stream.dart';

final class CandidateApp extends StatefulWidget {
  const CandidateApp({super.key});
  @override
  State<CandidateApp> createState() => _CandidateAppState();
}

class _CandidateAppState extends State<CandidateApp> {
  late final _auth = getIt<AuthCubit>();
  late final _refresh = GoRouterRefreshStream(_auth.stream);
  late final _router = createAppRouter(authCubit: _auth, refresh: _refresh);
  @override
  void initState() {
    super.initState();
    _auth.bootstrap();
  }

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _auth,
    child: MaterialApp.router(
      title: 'Autoškola 365',
      debugShowCheckedModeBanner: false,
      theme: DrivingSchoolTheme.light(),
      locale: const Locale('hr'),
      supportedLocales: const [Locale('hr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
    ),
  );
}
