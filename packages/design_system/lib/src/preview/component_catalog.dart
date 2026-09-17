import 'package:flutter/material.dart';
import '../../design_system.dart';

final class ComponentCatalog extends StatelessWidget {
  const ComponentCatalog({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Stanja komponenti',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: AppSpacing.lg),
      for (final variant in AppButtonVariant.values) ...[
        Text(variant.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(label: 'Spremi', variant: variant, onPressed: () {}),
            AppButton(label: 'Nedostupno', variant: variant, onPressed: null),
            AppButton(
              label: 'Spremi',
              loadingLabel: 'Spremanje…',
              variant: variant,
              isLoading: true,
              onPressed: null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: const [
          AppStatusBadge(label: 'U tijeku', tone: AppTone.info),
          AppStatusBadge(label: 'Potvrđeno', tone: AppTone.success),
          AppStatusBadge(label: 'Čeka potvrdu', tone: AppTone.warning),
          AppStatusBadge(label: 'Otkazano', tone: AppTone.error),
          AppStatusBadge(label: 'Arhivirano', tone: AppTone.neutral),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      const AppTextField(label: 'Standardno polje', initialValue: 'Ana Horvat'),
      const SizedBox(height: AppSpacing.md),
      const AppTextField(
        label: 'Greška',
        initialValue: 'ana',
        errorText: 'Unesite valjanu e-mail adresu.',
      ),
      const SizedBox(height: AppSpacing.md),
      const AppTextField(
        label: 'Onemogućeno',
        initialValue: 'Ana Horvat',
        enabled: false,
      ),
      const SizedBox(height: AppSpacing.lg),
      for (final elevation in AppElevation.values) ...[
        AppCard(
          elevation: elevation,
          child: Text('Elevation · ${elevation.name}'),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    ],
  );
}
