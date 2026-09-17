import 'package:flutter/material.dart';
import '../../design_system.dart';

final class CandidateDesignSystemExample extends StatelessWidget {
  const CandidateDesignSystemExample({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Kandidat · moj put',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: AppSpacing.lg),
      const AppProgressCard(
        title: 'TVOJ PUT DO VOZAČKE',
        valueLabel: '25 / 35',
        subtitle: 'odrađenih nastavnih sati',
        message:
            'Broje se dovršene vožnje. Spremnost za ispit potvrđuje instruktor.',
        progress: 25 / 35,
        progressSemanticsValue: '25 od 35 sati',
      ),
      const SizedBox(height: AppSpacing.md),
      const AppLessonCard(
        timeLabel: '19. rujna · 09:00 – 10:00',
        title: 'Zahtjev za vožnju',
        details: 'Marko Babić · 60 minuta',
        statusLabel: 'Čeka potvrdu',
        statusTone: AppTone.warning,
      ),
      const SizedBox(height: AppSpacing.md),
      const AppInfoCard(
        eyebrow: 'SLJEDEĆI KORAK',
        title: 'Pričekaj potvrdu',
        message: 'Predloženi termin još nije potvrđena vožnja.',
      ),
      const SizedBox(height: AppSpacing.md),
      const AppEmptyState(
        title: 'Nema završenih termina u ovom prikazu',
        message: 'Promijeni razdoblje za pregled drugih termina.',
      ),
    ],
  );
}
