import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/cubit/auth_cubit.dart';
import 'app_dependencies.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class InstructorApp extends StatefulWidget {
  const InstructorApp({super.key});

  @override
  State<InstructorApp> createState() => _InstructorAppState();
}

class _InstructorAppState extends State<InstructorApp> {
  late final _router = createAppRouter(authCubit: getIt<AuthCubit>());

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
        title: 'Auto Skola 365 Instruktor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
