import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/cubit/auth_cubit.dart';
import 'app_dependencies.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final _router = createAppRouter(
    authCubit: getIt<AuthCubit>(),
    loadSchoolOverview: getIt(),
    loadInstructorOverview: getIt(),
    listCandidates: getIt(),
    createCandidate: getIt(),
    updateCandidate: getIt(),
    listInstructors: getIt(),
    createInstructor: getIt(),
    updateInstructor: getIt(),
    listLessons: getIt(),
    createLesson: getIt(),
    updateLesson: getIt(),
    confirmLesson: getIt(),
    cancelLesson: getIt(),
  );

  @override
  void initState() {
    super.initState();
    getIt<AuthCubit>().bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>.value(
      value: getIt<AuthCubit>(),
      child: MaterialApp.router(
        title: 'Auto Skola 365 Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
