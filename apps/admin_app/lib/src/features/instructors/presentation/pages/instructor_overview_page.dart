import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/usecases/load_instructor_overview.dart';
import '../cubit/instructor_overview_cubit.dart';
import 'instructor_overview_view.dart';

final class InstructorOverviewPage extends StatelessWidget {
  const InstructorOverviewPage({
    required this.loadOverview,
    this.query = '',
    super.key,
  });
  final LoadInstructorOverview loadOverview;
  final String query;
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    return BlocProvider(
      key: ValueKey(
        '${auth.user!.primaryMembership!.schoolId}:${auth.accessToken}:$query',
      ),
      create: (_) => InstructorOverviewCubit(
        loadOverview: loadOverview,
        schoolId: auth.user!.primaryMembership!.schoolId,
        accessToken: auth.accessToken!,
      )..search(query, null),
      child: InstructorOverviewView(initialQuery: query),
    );
  }
}
