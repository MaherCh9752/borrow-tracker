import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Screen for managing appearance settings (theme selection).
class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your preferred appearance for the app.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ThemeOption(
                    icon: Icons.brightness_auto,
                    title: 'System',
                    subtitle: 'Follow device setting',
                    selected: themeProvider.themeMode == ThemeMode.system,
                    onTap: () =>
                        themeProvider.setThemeMode(ThemeMode.system),
                  ),
                  const Divider(height: 1),
                  _ThemeOption(
                    icon: Icons.light_mode,
                    title: 'Light',
                    subtitle: 'Always use light theme',
                    selected: themeProvider.themeMode == ThemeMode.light,
                    onTap: () =>
                        themeProvider.setThemeMode(ThemeMode.light),
                  ),
                  const Divider(height: 1),
                  _ThemeOption(
                    icon: Icons.dark_mode,
                    title: 'Dark',
                    subtitle: 'Always use dark theme',
                    selected: themeProvider.themeMode == ThemeMode.dark,
                    onTap: () =>
                        themeProvider.setThemeMode(ThemeMode.dark),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.palette,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Current Theme'),
              trailing: Text(
                themeProvider.currentLabel,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: selected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : Icon(Icons.circle_outlined, color: colorScheme.outline),
      onTap: onTap,
    );
  }
}
