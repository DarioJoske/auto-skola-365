import 'package:flutter/material.dart';
import '../../design_system.dart';

final class NavigationExample extends StatefulWidget {
  const NavigationExample({this.mode = AppNavigationMode.mobile, super.key});
  final AppNavigationMode mode;
  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int _index = 0;
  bool _loading = false;
  bool _failed = false;
  @override
  Widget build(BuildContext context) => AppNavigationShell(
    title: 'Autoškola 365',
    mode: widget.mode,
    selectedIndex: _index,
    onDestinationSelected: (index) => setState(() => _index = index),
    actions: [
      IconButton(
        tooltip: 'Odjava',
        onPressed: () => showSessionExpired(context),
        icon: const Icon(Icons.logout),
      ),
    ],
    destinations: widget.mode == AppNavigationMode.admin
        ? const [
            AppDestination(label: 'Pregled', icon: Icons.dashboard_outlined),
            AppDestination(label: 'Kandidati', icon: Icons.people_outline),
            AppDestination(label: 'Instruktori', icon: Icons.badge_outlined),
            AppDestination(
              label: 'Vožnje',
              icon: Icons.calendar_month_outlined,
            ),
            AppDestination(label: 'Postavke', icon: Icons.settings_outlined),
          ]
        : const [
            AppDestination(label: 'Pregled', icon: Icons.home_outlined),
            AppDestination(
              label: 'Termini',
              icon: Icons.calendar_month_outlined,
            ),
            AppDestination(label: 'Moj profil', icon: Icons.person_outline),
          ],
    child: ListView(
      children: [
        AppPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tvoji termini',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
              const AppEmptyState(
                title: 'Raspored je još prazan',
                message: 'Dogovori prvi termin s instruktorom.',
              ),
              const SizedBox(height: 24),
              const TextField(
                decoration: InputDecoration(labelText: 'Bilješka'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _loading = !_loading;
                      _failed = false;
                    }),
                    child: const Text('Osvježi'),
                  ),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _failed = true;
                      _loading = false;
                    }),
                    child: const Text('Prikaži grešku'),
                  ),
                  TextButton(
                    onPressed: () => showAppConfirmation(
                      context,
                      title: 'Otkazati termin?',
                      message: 'Termin će biti otkazan.',
                      confirmLabel: 'Otkaži termin',
                    ),
                    child: const Text('Potvrda'),
                  ),
                ],
              ),
              if (_loading) const AppLoadingState(isRefreshing: true),
              if (_failed)
                AppInlineError(
                  message: 'Usluga privremeno nije dostupna.',
                  onRetry: () => setState(() {
                    _loading = true;
                    _failed = false;
                  }),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
