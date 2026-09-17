import 'package:flutter/material.dart';
import '../../design_system.dart';

final class InstructorDesignSystemExample extends StatelessWidget {
  const InstructorDesignSystemExample({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Instruktor · moj dan',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: AppSpacing.lg),
      AppLessonCard(
        timeLabel: '16:30 – 17:30',
        title: 'Ana Horvat',
        details: 'Vožnja · B kategorija · 60 minuta',
        statusLabel: 'Potvrđeno',
        statusTone: AppTone.success,
        location: 'Polazak: autoškola',
        action: AppButton(
          label: 'Detalji termina',
          variant: AppButtonVariant.tonal,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pokazni termin · bez promjene evidencije.'),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      const AppTextField(
        label: 'Interna bilješka (neobavezno)',
        helperText: 'Vidljiva samo ovlaštenom osoblju škole.',
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
      ),
      const SizedBox(height: AppSpacing.md),
      const AppButton(label: 'Završi sat', onPressed: null),
      const SizedBox(height: AppSpacing.md),
      const AppNotice(
        title: 'Termin još traje',
        message: 'Sat se može završiti nakon isteka termina.',
        tone: AppTone.warning,
      ),
      const SizedBox(height: AppSpacing.md),
      const AppListItem(
        title: 'Ana Horvat',
        subtitle: 'B kategorija · 25/35 sati',
        leading: CircleAvatar(child: Text('AH')),
      ),
    ],
  );
}
