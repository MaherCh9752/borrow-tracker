# Borrow Tracker — Project State

## Goal
A production-ready Flutter mobile app for tracking borrowed and lent money, with real-time sync, local notifications (even when the app is killed), and a polished Material 3 UI.

## Stack
- **Flutter** 3.35+ / **Dart** 3.9+
- **Firebase Auth** (email/password)
- **Cloud Firestore** (real-time streams)
- **Provider** (state management)
- **flutter_local_notifications** (in-app delivery)
- **workmanager** (background delivery — `JobScheduler` on Android)
- **shared_preferences** (first-run tracking)
- **fl_chart** (charts & graphs)
- **connectivity_plus** (online/offline detection)
- **pdf** (PDF generation)
- **printing** (PDF preview, share, print)
- **csv** (CSV generation)
- **file_picker** (save location picker for CSV)
- **local_auth** (biometric authentication)
- **flutter_secure_storage** (encrypted preference storage)

## Implemented Features

### Authentication
- Email/password sign-up with display name
- Email/password sign-in
- Password reset via email
- Auth state persistence on cold start
- Form validation and FirebaseAuthException error mapping
- Firestore user document created on first sign-in

### Entry Management (CRUD)
- `BorrowLend` model with `EntryType` (`borrow`/`lend`) and `EntryStatus` (`pending`/`paid`/`partial`)
- Firestore collection: `users/{uid}/borrowLendEntries/{entryId}`
- Add, edit, delete with real-time sync
- Status toggle (paid / pending / partial) from list view
- Pull-to-refresh and loading/error states

### Dashboard
- Summary cards: Total Borrowed (orange), Total Lent (teal)
- Stats cards: Pending count, Upcoming deadlines (next 7 days)
- Recent entries list (last 5) with status chip and relative time
- Empty state, pull-to-refresh, FAB for adding entries

### All Records & Search / Filters
- Scrollable list with popup menu (edit / mark paid / mark partial / delete)
- Text search by person name (case-insensitive)
- Status filter (Pending / Paid / Partial)
- Type filter (Borrowed / Lent)
- Currency filter (dynamically populated)
- Deadline filter (Has deadline / No deadline / Overdue / Next 7 days)
- Bottom-sheet filter picker with active-chip highlighting
- Clear-all button, distinct empty states

### Notifications
- **`ReminderSettings`** model persisted in Firestore (`reminderSettings` map inside user doc):
  - `notificationsEnabled` (master toggle)
  - `remindOnDayOfDeadline` (fire at configured time on the due date)
  - `upcomingDeadlineReminders` + `reminderDaysBefore` (1/3/7 days before)
  - `overdueReminders` + `dailyOverdueReminder` (once, or daily until cleared)
  - `reminderHour` + `reminderMinute` (24h, default 09:00)
  - `setupCompleted` (flag used by settings UI)
- **In-app delivery**: 5-second `Timer.periodic` checks a `_pending` list and calls `showNotification()` — fires instantly while the app is alive.
- **Background delivery**: `Workmanager` (`registerOneOffTask` / `registerPeriodicTask` with 24h frequency) persists alarms via Android `JobScheduler`. Fires even when the app is killed.
- **Time spreading**: Per-entry deterministic offset (`entryId.hash % 5 + typeOffset * 5`) spreads simultaneous notifications 5 seconds apart to avoid the Android `NotificationManager` dropping same-timestamp calls.
- **`_normalizeTime`** 10-second grace window prevents microsecond-precision time comparison bugs from pushing notifications a full day ahead.
- **`_fireDue`** concurrency guard (`_firingNow`) prevents race between overlapping timer ticks.
- WorkManager tasks are cancelled after in-app delivery to prevent duplicates.
- **First-run prompt**: Shown once at app boot (before login) via `SharedPreferences` flag. "Enable" requests OS notification + exact-alarm permissions. The flag `notification_enabled_from_boot` auto-enables Firestore settings after login, then self-destructs to never override the user's choice.
- **Settings screen** (bell icon on dashboard): master toggle, individual toggles, time picker, day-before frequency, save to Firestore.

### Statistics / Charts
- **Three chart types** on a dedicated Statistics screen (bar chart icon in dashboard AppBar)
- **Monthly Totals**: Grouped bar chart showing borrowed (orange) vs lent (teal) per month
- **Payment Status**: Pie chart splitting total amount into paid (green) vs unpaid (orange) with percentages
- **Debt History**: Curved line chart tracking net cumulative debt over time (borrow adds, lent subtracts)
- **Smart labels**: Sparse axis labels avoid clutter; edge values hidden for cleaner look
- **Empty state**: Friendly message when no entries exist
- Powered by `fl_chart` 0.69+

### Material 3 UI
- `useMaterial3: true`, `ColorScheme.fromSeed`
- Segmented buttons, outlined buttons, filled buttons, snack bars, floating action button
- Bottom sheet for filter selection
- Status chips with semantic colors
- Responsive form layout

### Offline Support
- **Firestore persistence** enabled explicitly with unlimited cache size in `main.dart`
- **`ConnectivityService`** wraps `connectivity_plus` to monitor network status via `onConnectivityChanged` stream
- **`ConnectivityProvider`** exposes `isOnline` to the widget tree via Provider
- **`OfflineIndicator`** widget: orange banner shown at the top of Dashboard and All Records screens when offline
- Firestore automatically queues writes offline and syncs when reconnected
- Data reads served from local cache when offline
- **Offline-safe CRUD**: All save buttons (Add Entry, Edit Entry, Save Settings) use 500ms timeout + `try-catch-finally` — always navigate back even when offline (Firestore queues writes locally)
- **Fallback caching**: Notification settings fall back to `SharedPreferences` if Firestore write fails

### Export to PDF
- **`PdfService`** generates landscape A4 PDF with `pdf` package
- **Table columns**: #, Person, Type, Amount, Currency, Status, Date, Deadline, Notes
- **Summary section**: Total entries, total borrowed/lent, pending/paid counts
- **`PdfPreviewScreen`** shows live preview + share/print via `printing` package
- Export button in **Dashboard AppBar** (exports all entries) and **All Records AppBar** (exports filtered entries)
- Empty state handling when no entries exist

### Export to CSV
- **`CsvService`** generates CSV with `csv` package (proper quoting for edge cases)
- **Headers**: #, Person, Type, Amount, Currency, Status, Date, Deadline, Notes
- **ISO date format**: `YYYY-MM-DD` for spreadsheet compatibility
- **`CsvPreviewScreen`** shows DataTable preview + save to chosen location via `file_picker`
- Export button in **Dashboard AppBar** (exports all entries) and **All Records AppBar** (exports filtered entries)
- User stays on preview screen after saving — can save multiple times to different locations

### Biometric App Lock (Optional)
- **`BiometricService`** wraps `local_auth` — checks hardware, enrollment, prompts biometric auth
- **`SecurityProvider`** manages app lock state, persists preference in `flutter_secure_storage`
- **`SecuritySettingsScreen`** — toggle app lock, shows device compatibility status
- **Lock gate in `main.dart`** — `_BiometricLockScreen` prompts authentication on app launch
- **`_AppLifecycleObserver`** — sits below `MultiProvider`, detects app pause/resume to lock
- **Pause-based locking** — sets `_pendingLock` on pause; only locks on resume if pending (avoids biometric dialog loop)
- **`_isAuthenticating` flag** — prevents `onAppPaused()` from setting pending lock during biometric prompt
- **Auto-disable** — if user removes biometrics after enabling lock, preference is cleared
- **Fallback** — `biometricOnly: false` allows device PIN/pattern as fallback
- **Android**: `USE_BIOMETRIC` permission + `FlutterFragmentActivity` (required by `local_auth`)
- **iOS**: `NSFaceIDUsageDescription` in Info.plist

## Architecture

```
lib/
├── main.dart                          # App entry, providers, WorkManager init, first-run gate
├── firebase_options.dart              # Firebase config (generated)
├── models/
│   ├── user_model.dart                # User data model
│   ├── borrow_lend.dart               # Borrow/lend entry model + enums
│   └── reminder_settings.dart         # Notification settings model
├── services/
│   ├── auth_service.dart              # Firebase Auth operations
│   ├── entry_service.dart             # Firestore CRUD
│   ├── notification_service.dart      # flutter_local_notifications + WorkManager scheduling
│   ├── notification_callback.dart     # Top-level WorkManager dispatcher (background isolate)
│   ├── connectivity_service.dart      # Monitors online/offline status via connectivity_plus
│   ├── pdf_service.dart               # PDF generation with table + summary
│   ├── csv_service.dart               # CSV generation with headers
│   └── biometric_service.dart         # Biometric authentication via local_auth
├── providers/
│   ├── auth_provider.dart             # Auth state
│   ├── entry_provider.dart            # Entry state, filters, aggregates
│   ├── notification_provider.dart     # Settings persistence, schedule logic, timer, _fireDue
│   ├── connectivity_provider.dart     # Exposes isOnline to the widget tree
│   └── security_provider.dart         # App lock state, enable/disable, biometric auth
├── screens/
│   ├── auth_screen.dart               # Login / Sign up / Password reset
│   ├── dashboard_screen.dart          # Summary cards, recent entries, nav
│   ├── all_records_screen.dart        # Full list with actions & filters
│   ├── add_edit_entry_screen.dart     # Entry form (add & edit)
│   ├── notification_settings_screen.dart # Reminder config UI
│   ├── statistics_screen.dart         # Charts: monthly totals, payment status, debt history
│   ├── pdf_preview_screen.dart        # PDF preview + share/print
│   ├── csv_preview_screen.dart        # CSV preview + save to file
│   └── security_settings_screen.dart  # Biometric app lock toggle + device status
├── widgets/
│   └── offline_indicator.dart         # Orange banner shown when offline
└── utils/
    └── constants.dart                 # App-wide constants
```

## Foundation & Config
- Flutter SDK 3.35+, Dart 3.9+
- Null safety, `copyWith` / `toMap` / `fromMap` everywhere
- `coreLibraryDesugaring` enabled for `java.time` API on older Android
- `USE_EXACT_ALARM` + `SCHEDULE_EXACT_ALARM` + `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED` declared in `AndroidManifest.xml`
- `shared_preferences` for first-run prompt flag
- Remote: `https://github.com/MaherCh9752/borrow-tracker.git`

## Pending
- None (all planned features implemented)
