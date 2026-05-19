class ReminderSettings {
  final bool upcomingDeadlineReminders;
  final bool overdueReminders;
  final int reminderDaysBefore;
  final bool remindOnDayOfDeadline;
  final bool dailyOverdueReminder;
  final int reminderHour;
  final int reminderMinute;
  final bool notificationsEnabled;
  final bool setupCompleted;

  const ReminderSettings({
    this.upcomingDeadlineReminders = true,
    this.overdueReminders = true,
    this.reminderDaysBefore = 3,
    this.remindOnDayOfDeadline = true,
    this.dailyOverdueReminder = false,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.notificationsEnabled = false,
    this.setupCompleted = false,
  });

  ReminderSettings copyWith({
    bool? upcomingDeadlineReminders,
    bool? overdueReminders,
    int? reminderDaysBefore,
    bool? remindOnDayOfDeadline,
    bool? dailyOverdueReminder,
    int? reminderHour,
    int? reminderMinute,
    bool? notificationsEnabled,
    bool? setupCompleted,
  }) {
    return ReminderSettings(
      upcomingDeadlineReminders:
          upcomingDeadlineReminders ?? this.upcomingDeadlineReminders,
      overdueReminders: overdueReminders ?? this.overdueReminders,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      remindOnDayOfDeadline:
          remindOnDayOfDeadline ?? this.remindOnDayOfDeadline,
      dailyOverdueReminder: dailyOverdueReminder ?? this.dailyOverdueReminder,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      setupCompleted: setupCompleted ?? this.setupCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'upcomingDeadlineReminders': upcomingDeadlineReminders,
      'overdueReminders': overdueReminders,
      'reminderDaysBefore': reminderDaysBefore,
      'remindOnDayOfDeadline': remindOnDayOfDeadline,
      'dailyOverdueReminder': dailyOverdueReminder,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'notificationsEnabled': notificationsEnabled,
      'setupCompleted': setupCompleted,
    };
  }

  factory ReminderSettings.fromMap(Map<String, dynamic> map) {
    return ReminderSettings(
      upcomingDeadlineReminders:
          map['upcomingDeadlineReminders'] ?? true,
      overdueReminders: map['overdueReminders'] ?? true,
      reminderDaysBefore: map['reminderDaysBefore'] ?? 3,
      remindOnDayOfDeadline: map['remindOnDayOfDeadline'] ?? true,
      dailyOverdueReminder: map['dailyOverdueReminder'] ?? false,
      reminderHour: map['reminderHour'] ?? 9,
      reminderMinute: map['reminderMinute'] ?? 0,
      notificationsEnabled: map['notificationsEnabled'] ?? false,
      setupCompleted: map['setupCompleted'] ?? false,
    );
  }
}
