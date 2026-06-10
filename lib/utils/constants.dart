class AppConstants {
  static const String appName = 'Borrow Tracker';
  static const String usersCollection = 'users';
  static const String entriesSubCollection = 'borrowLendEntries';
  static const String notificationChannelId = 'deadline_reminders';
  static const String notificationChannelName = 'Deadline Reminders';
  static const String notificationChannelDescription =
      'Reminders for upcoming and overdue deadlines';
  static const String offlineMessage =
      'You\'re offline. Changes will sync when reconnected.';
  static const String secureStorageAppLockKey = 'app_lock_enabled';
  static const String themePreferenceKey = 'theme_mode';
  static const String defaultCurrency = 'TND';
  static const int currencyDecimals = 3;
}