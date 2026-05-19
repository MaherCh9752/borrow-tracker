import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder_settings.dart';
import '../providers/notification_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late ReminderSettings _draft;

  @override
  void initState() {
    super.initState();
    final settings = context.read<NotificationProvider>().settings;
    _draft = settings;
  }

  Future<void> _save() async {
    final provider = context.read<NotificationProvider>();
    await provider.updateSettings(_draft);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive reminders for deadlines'),
            value: _draft.notificationsEnabled,
            onChanged: (v) => setState(() => _draft =
                _draft.copyWith(notificationsEnabled: v, setupCompleted: true)),
          ),
          const Divider(),
          if (_draft.notificationsEnabled) ...[
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Reminder Time'),
              subtitle: Text(
                '${_draft.reminderHour.toString().padLeft(2, '0')}:'
                '${_draft.reminderMinute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: _draft.reminderHour,
                    minute: _draft.reminderMinute,
                  ),
                );
                if (picked != null) {
                  setState(() => _draft = _draft.copyWith(
                    reminderHour: picked.hour,
                    reminderMinute: picked.minute,
                  ));
                }
              },
            ),
            const Divider(),
            _buildSectionHeader(theme, 'Upcoming Deadlines'),
            SwitchListTile(
              title: const Text('Upcoming Deadline Reminders'),
              subtitle: const Text('Get reminded before a deadline'),
              value: _draft.upcomingDeadlineReminders,
              onChanged: (v) => setState(
                  () => _draft = _draft.copyWith(upcomingDeadlineReminders: v)),
            ),
            if (_draft.upcomingDeadlineReminders)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text('Remind me'),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: _draft.reminderDaysBefore,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 day')),
                        DropdownMenuItem(value: 3, child: Text('3 days')),
                        DropdownMenuItem(value: 7, child: Text('7 days')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _draft =
                              _draft.copyWith(reminderDaysBefore: v));
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    const Text('before'),
                  ],
                ),
              ),
            SwitchListTile(
              title: const Text('Remind on Day of Deadline'),
              subtitle: const Text('Notification when it is due'),
              value: _draft.remindOnDayOfDeadline,
              onChanged: (v) => setState(
                  () => _draft = _draft.copyWith(remindOnDayOfDeadline: v)),
            ),
            const Divider(),
            _buildSectionHeader(theme, 'Overdue Reminders'),
            SwitchListTile(
              title: const Text('Overdue Reminders'),
              subtitle: const Text('Get notified when a deadline passes'),
              value: _draft.overdueReminders,
              onChanged: (v) => setState(
                  () => _draft = _draft.copyWith(overdueReminders: v)),
            ),
            if (_draft.overdueReminders)
              SwitchListTile(
                title: const Text('Daily Overdue Reminder'),
                subtitle: const Text('Remind every day until resolved'),
                value: _draft.dailyOverdueReminder,
                onChanged: (v) => setState(
                    () => _draft = _draft.copyWith(dailyOverdueReminder: v)),
              ),
          ],
          if (_draft.notificationsEnabled) ...[
            const Divider(),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
