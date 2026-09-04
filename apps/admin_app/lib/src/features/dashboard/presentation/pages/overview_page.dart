import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final membership = user.primaryMembership;

    return ListView(
      children: [
        Text(
          'Dobro dosao, ${user.fullName}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(user.email),
        const SizedBox(height: 24),
        if (membership != null)
          _Section(
            title: membership.schoolName,
            children: [
              _InfoRow(
                label: 'Status clanstva',
                value: membership.membershipStatus,
              ),
              _InfoRow(label: 'Rola', value: membership.roleName),
              _InfoRow(label: 'Scope', value: membership.roleScope),
            ],
          ),
        const SizedBox(height: 16),
        _Section(
          title: 'Permissions',
          children: [
            if (membership == null || membership.permissions.isEmpty)
              const Text('Nema dodijeljenih permissions.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final permission in membership.permissions)
                    Chip(label: Text(permission)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
