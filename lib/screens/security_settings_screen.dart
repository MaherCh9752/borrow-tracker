import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../theme/app_theme.dart';

/// Settings screen for configuring biometric app lock.
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecurityProvider>().refreshAvailability();
    });
  }

  Future<void> _toggleLock(bool value) async {
    if (_isProcessing) return;

    final provider = context.read<SecurityProvider>();
    setState(() => _isProcessing = true);

    bool success;
    if (value) {
      success = await provider.enableLock();
    } else {
      success = await provider.disableLock();
    }

    if (mounted) {
      setState(() => _isProcessing = false);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Authentication cancelled or failed.'),
            backgroundColor: AppColors.pendingLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<SecurityProvider>();
    final availability = provider.availability;

    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(theme, colorScheme, provider, availability),
          const SizedBox(height: 20),
          _buildAppLockSection(theme, colorScheme, provider, availability),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    ColorScheme colorScheme,
    SecurityProvider provider,
    availability,
  ) {
    final hasHardware = availability?.hasHardware ?? false;
    final hasEnrolled = availability?.hasEnrolled ?? false;
    final types = availability?.typeNames ?? 'Unknown';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _statusRow(
              theme,
              colorScheme,
              'Biometric Hardware',
              hasHardware ? 'Available' : 'Not available',
              hasHardware ? colorScheme.primary : colorScheme.error,
            ),
            const SizedBox(height: 8),
            _statusRow(
              theme,
              colorScheme,
              'Credentials Enrolled',
              hasEnrolled ? 'Yes' : 'No',
              hasEnrolled ? colorScheme.primary : colorScheme.error,
            ),
            const SizedBox(height: 8),
            _statusRow(
              theme,
              colorScheme,
              'Available Types',
              types,
              colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    String value,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAppLockSection(
    ThemeData theme,
    ColorScheme colorScheme,
    SecurityProvider provider,
    availability,
  ) {
    final isDeviceReady = (availability?.isAvailable ?? false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Lock',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Require biometric authentication when opening the app or returning from background.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (!isDeviceReady)
              _buildDisabledToggle(theme, colorScheme, availability)
            else
              SwitchListTile(
                title: const Text('Enable App Lock'),
                subtitle: Text(
                  provider.appLockEnabled ? 'Active' : 'Disabled',
                  style: TextStyle(
                    color: provider.appLockEnabled
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                value: provider.appLockEnabled,
                onChanged: _isProcessing ? null : _toggleLock,
                secondary: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        provider.appLockEnabled
                            ? Icons.lock
                            : Icons.lock_open,
                        color: provider.appLockEnabled
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledToggle(
      ThemeData theme, ColorScheme colorScheme, availability) {
    final hasHardware = availability?.hasHardware ?? false;
    String reason;
    if (!hasHardware) {
      reason = 'This device does not have biometric hardware.';
    } else {
      reason =
          'No biometrics enrolled. Please add a fingerprint or face in your device settings.';
    }

    return ListTile(
      leading: Icon(Icons.lock_open, color: colorScheme.onSurfaceVariant),
      title: const Text('Enable App Lock'),
      subtitle: Text(
        reason,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
