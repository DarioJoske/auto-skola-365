import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';

final class AppDestination {
  const AppDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

enum AppNavigationMode { admin, mobile }

/// Presentation only: the application owns routes, identity and callbacks.
final class AppNavigationShell extends StatelessWidget {
  const AppNavigationShell({
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    this.mode = AppNavigationMode.mobile,
    this.subtitle,
    this.identityInSidebar = false,
    this.actions = const [],
    super.key,
  });
  final bool identityInSidebar;
  final String title;
  final String? subtitle;
  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final AppNavigationMode mode;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final admin = mode == AppNavigationMode.admin;
      final rail = admin && constraints.maxWidth >= 600;
      final expanded = rail && constraints.maxWidth >= 1200;
      final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      return Scaffold(
        drawer: admin && !rail
            ? Drawer(
                child: SafeArea(child: Builder(builder: _sidebar)),
              )
            : null,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (rail)
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: SizedBox(
                    width: expanded ? 256 : 80,
                    child: expanded
                        ? _sidebar(context)
                        : SingleChildScrollView(
                            primary: false,
                            child: IntrinsicHeight(
                              child: NavigationRail(
                                selectedIndex: selectedIndex,
                                onDestinationSelected: onDestinationSelected,
                                leading: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Icon(Icons.route_outlined),
                                ),
                                trailing: identityInSidebar
                                    ? Column(children: actions)
                                    : null,
                                destinations: [
                                  for (final destination in destinations)
                                    NavigationRailDestination(
                                      icon: Tooltip(
                                        message: destination.label,
                                        child: Icon(destination.icon),
                                      ),
                                      selectedIcon: Tooltip(
                                        message: destination.label,
                                        child: Icon(
                                          destination.selectedIcon ??
                                              destination.icon,
                                        ),
                                      ),
                                      label: Text(destination.label),
                                    ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              if (rail && !identityInSidebar) const VerticalDivider(width: 1),
              Expanded(
                key: const ValueKey('shell-content'),
                child: Column(
                  children: [
                    if (!rail || !identityInSidebar) ...[
                      Material(
                        color: Theme.of(context).colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.space12,
                          ),
                          child: Row(
                            children: [
                              if (admin && !rail)
                                Builder(
                                  builder: (context) => IconButton(
                                    tooltip: 'Otvori navigaciju',
                                    onPressed: () =>
                                        Scaffold.of(context).openDrawer(),
                                    icon: const Icon(Icons.menu),
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    if (subtitle != null)
                                      Text(
                                        subtitle!,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              ...actions,
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: !admin && !keyboardVisible
            ? NavigationBar(
                height: 76 + (scale - 1).clamp(0, 3) * 32,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: [
                  for (final destination in destinations)
                    NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(
                        destination.selectedIcon ?? destination.icon,
                      ),
                      label: destination.label,
                    ),
                ],
              )
            : null,
      );
    },
  );

  Widget _sidebar(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: ListView(
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.route_outlined),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Text(
                'autoškola 365',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (identityInSidebar)
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        const Divider(),
        for (var index = 0; index < destinations.length; index++)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: ListTile(
              shape: const StadiumBorder(),
              selected: selectedIndex == index,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
              leading: Icon(
                selectedIndex == index
                    ? destinations[index].selectedIcon ??
                          destinations[index].icon
                    : destinations[index].icon,
              ),
              title: Text(
                destinations[index].label,
                style: identityInSidebar
                    ? Theme.of(context).textTheme.labelLarge
                    : null,
              ),
              iconColor: identityInSidebar
                  ? Theme.of(context).colorScheme.onSurface
                  : null,
              selectedColor: identityInSidebar
                  ? Theme.of(context).colorScheme.onSurface
                  : null,
              onTap: () {
                Scaffold.maybeOf(context)?.closeDrawer();
                onDestinationSelected(index);
              },
            ),
          ),
        if (identityInSidebar) ...[
          const SizedBox(height: AppSpacing.md),
          if (subtitle != null)
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          Wrap(children: actions),
        ],
      ],
    ),
  );
}
