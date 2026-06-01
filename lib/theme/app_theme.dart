import 'package:flutter/material.dart';
import '../models/borrow_lend.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

/// Central theme accessor for the app.
class AppTheme {
  AppTheme._();

  static ThemeData get light => LightTheme.build();
  static ThemeData get dark => DarkTheme.build();
}

/// Semantic color tokens used throughout the app.
/// These remain consistent across themes for brand continuity.
class AppColors {
  AppColors._();

  // Domain colors — same in light & dark for brand consistency.
  static const Color borrowColor = Color(0xFFE65100);
  static const Color lendColor = Color(0xFF00897B);

  // Status colors — light mode variants.
  static const Color paidLight = Color(0xFF2E7D32);
  static const Color pendingLight = Color(0xFFEF6C00);
  static const Color partialLight = Color(0xFF1565C0);
  static const Color overdueLight = Color(0xFFC62828);

  // Status colors — dark mode variants (brighter for dark backgrounds).
  static const Color paidDark = Color(0xFF66BB6A);
  static const Color pendingDark = Color(0xFFFFA726);
  static const Color partialDark = Color(0xFF42A5F5);
  static const Color overdueDark = Color(0xFFEF5350);

  // Chart colors — consistent across both themes.
  static const Color chartBorrow = Color(0xFFE65100);
  static const Color chartLend = Color(0xFF00897B);
  static const Color chartPaid = Color(0xFF2E7D32);
  static const Color chartUnpaid = Color(0xFFEF6C00);
  static const Color chartLine = Color(0xFF3F51B5);

  // Stats cards.
  static const Color statsPending = Color(0xFF3F51B5);
  static const Color statsDeadline = Color(0xFF7B1FA2);

  // Offline indicator banner.
  static const Color offlineBanner = Color(0xFFE65100);

  /// Returns the appropriate status color for the given [status]
  /// based on the current [brightness].
  static Color forStatus(EntryStatus status, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (status) {
      case EntryStatus.paid:
        return isDark ? paidDark : paidLight;
      case EntryStatus.pending:
        return isDark ? pendingDark : pendingLight;
      case EntryStatus.partial:
        return isDark ? partialDark : partialLight;
    }
  }

  /// Returns overdue color based on brightness.
  static Color overdue(Brightness brightness) {
    return brightness == Brightness.dark ? overdueDark : overdueLight;
  }
}
