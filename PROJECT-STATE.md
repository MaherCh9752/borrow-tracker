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
- **qr_flutter** (QR code generation for invites)
- **share_plus** (system share sheet for invite links)

## Implemented Features

### Authentication
- Email/password sign-up with display name
- Email/password sign-in
- Password reset via email
- Auth state persistence on cold start
- Form validation and FirebaseAuthException error mapping
- Firestore user document created on first sign-in

### Net Balance Calculation
- **`netBalance`** getter: overall net debt (totalLent - totalBorrowed) — positive = others owe you, negative = you owe others, zero = settled
- **`calculateNetBalance(otherUserId)`**: net balance with a specific user
- **`netBalancesByUser`**: map of all user IDs to their net balance
- **Dashboard Net Balance card**: shows amount with color-coded label ("Others owe you" / "You owe others" / "Settled")

### Shared Entry Management (CRUD)
- `SharedEntry` model extending `BorrowLend` with `createdBy`, `createdByName`, `participants`, `linkedUserId`, `linkedUserName`, `approvalStatus`, and `deadline` fields
- **`createdByName`**: stores creator's display name — used for "Created by X" in pending requests and entry labels
- Firestore collection: `shared_entries/{entryId}` — single source of truth, no duplication per user
- Participants array of user IDs — entry appears for all participants via `ARRAY-CONTAINS` query
- Default personal entries: entries without selected participants default to `participants: [currentUserId]`
- Add, edit, delete with real-time sync across all participants
- Status toggle (paid / pending / partial) from list view — any participant can update
- Delete restricted to creator only (hidden from non-creator popup menus)
- Participant count badge shown on entries with multiple participants
- Pull-to-refresh and loading/error states

### UserSearchField Widget
- Smart searchable text field that queries Firestore users by displayName or email
- 300ms debounced search with autocomplete overlay
- Loading, no-results, and error states in the overlay
- Locks after a user is selected — read-only with primary tint and filled background
- Clear button (X) resets the selection and allows re-searching
- Shows invite options (QR Code / Share Link) when no users are found
- Returns `selectedUserId` to parent via `onSelected` callback (nullable)

### Debt Linking
- `linkedUserId` and `linkedUserName` fields on `SharedEntry` — links a debt to a specific user account
- `approvalStatus` enum: `PENDING_APPROVAL`, `ACTIVE`, `REJECTED`
- New debts with a linked user default to `approvalStatus: PENDING_APPROVAL`
- Linked user is automatically added to the `participants` array for Firestore visibility
- **Entry type inversion**: When User A creates a "borrow" entry linking to User B, it appears as a "lend" entry for User B (and vice versa) via `entryTypeFor(userId)`

### Debt Approval Workflow
- **PendingRequestsScreen** with four sections:
  - **Waiting for approval**: Entries you created that are pending the linked user's approval — shows linked user name
  - **Needs your approval**: Entries others created linking to you — shows creator's name (`createdByName`) with accept/reject buttons
  - **Change requests**: Incoming edit proposals from other users with diff display and accept/reject
  - **Your change requests**: Outgoing edit proposals awaiting the other user's approval with cancel option
- **Accept**: Sets `approvalStatus = ACTIVE` via partial update (`editEntryFromMap`) — entry now counts in dashboard/statistics
- **Reject**: Sets `approvalStatus = REJECTED` via partial update — entry excluded from all calculations
- Badge count on dashboard hamburger menu showing total pending requests

### Change Request System (Edit Workflow)
- Editing a shared entry creates a **change request** instead of direct modification
- Change request stores proposed changes as a map — entry remains unchanged until accepted
- **Accept**: Applies proposed changes to the entry via `editEntryFromMap()` (preserves `participants`)
- **Reject**: Discards proposed changes — entry unchanged
- **Cancel**: Creator can cancel their own pending change request
- Approver determined dynamically: creator edits → linked user approves, linked user edits → creator approves
- Diff display shows exactly what changed (amount, type, currency, status, deadline, notes, person)

### User Invitation System
- When no users are found in search, shows **Invite by QR Code** and **Share Link** buttons
- **`PendingInvite`** model with `token`, `inviteCode`, `createdBy`, `targetPersonName`, `status`, `createdAt`, `expiresAt`
- **`InviteService`** creates invites in `pending_invites` Firestore collection
- 32-char random token (internal) + 6-char uppercase invite code (human-readable)
- 7-day expiration
- **InvitePreviewScreen** displays:
  - QR code (encodes `borrowtracker://invite?code=XXX`)
  - Invite code with copy-to-clipboard button
  - Share button (system share sheet with invite text)
- Firestore security rules for `pending_invites` (creator CRUD, public read for code lookup)

### Dashboard
- Summary cards: Total Borrowed (orange), Total Lent (teal)
- **Net Balance card**: Shows net debt (positive = others owe you, negative = you owe others, zero = settled)
- Stats cards: Pending count, Upcoming deadlines (next 7 days)
- **Grouped by Person section**: Shows each linked person as a card with avatar, lent/borrowed totals, net balance, next deadline, and expand/collapse — sorted alphabetically
- **Expandable person cards** (StatefulWidget): tap to expand and see individual entries sorted by deadline priority
- **Entry details in expanded view**: colored bar (borrow/lend), amount with sign, status chip, date, deadline (color-coded: red overdue, orange ≤3d, gray otherwise)
- Tap an entry → opens edit screen
- Empty state, pull-to-refresh, FAB for adding entries
- **Redesigned AppBar**: centered logo icon (`Icons.account_balance_wallet`) + "Borrow Tracker" title, hamburger menu (`PopupMenuButton`) on the left with all navigation items, logout button on the right
- **Hamburger menu items**: All Records, Grouped by Person, Pending Requests (with badge), Statistics | Export to CSV, Export to PDF | Notifications, Appearance, Security — grouped with dividers
- **`_MenuTile`** widget: consistent icon + label rows in the popup menu with optional badge
- Dashboard calculations exclude `PENDING_APPROVAL` and `REJECTED` entries

### All Records & Search / Filters
- Scrollable list with popup menu (edit / mark paid / mark partial / delete)
- Text search by person name (case-insensitive)
- Status filter (Pending / Paid / Partial)
- Type filter (Borrowed / Lent) — uses `entryTypeFor()` to resolve type per user before filtering
- Currency filter (dynamically populated)
- Deadline filter (Has deadline / No deadline / Overdue / Next 7 days)
- Bottom-sheet filter picker with active-chip highlighting
- Clear-all button, distinct empty states
- Relation label per entry: "from X" (other user's entry) or "with X" (your entry)
- **Due date priority sorting**: overdue first → nearest deadline → future deadline → no deadline; paid entries pushed to end within each tier

### Grouped by Person
- **PersonGroup** model: `personId`, `personName`, `entries`, `totalLent`, `totalBorrowed`, `netBalance`, `nextDeadline`
- **`groupedEntries`** getter on `SharedEntryProvider`: groups filtered entries by the other person
- **GroupedEntriesScreen**: expandable card list with search, filters, and sorting
- **Person group header**: avatar with initial, person name, lent/borrowed totals, net balance (color-coded), next deadline (color-coded), expand/collapse icon
- **Expandable entry list**: animated cross-fade showing individual entries with amount, status, date, and deadline
- **Search**: filters groups by person name (case-insensitive)
- **Filters**: status, type, currency, deadline — same as All Records
- **Navigation**: hamburger menu → "Grouped by Person"

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
- **Settings screen** (hamburger menu → Notifications): master toggle, individual toggles, time picker, day-before frequency, save to Firestore.

### Statistics / Charts
- **Three chart types** on a dedicated Statistics screen (hamburger menu → Statistics)
- **Monthly Totals**: Grouped bar chart showing borrowed (orange) vs lent (teal) per month
- **Payment Status**: Pie chart splitting total amount into paid (green) vs unpaid (orange) with percentages
- **Debt History**: Curved line chart tracking net cumulative debt over time (borrow adds, lent subtracts)
- **Smart labels**: Sparse axis labels avoid clutter; edge values hidden for cleaner look
- **Empty state**: Friendly message when no entries exist
- All charts respect entry type inversion per user via `entryTypeFor(userId)`
- Powered by `fl_chart` 0.69+

### Material 3 UI
- `useMaterial3: true`, `ColorScheme.fromSeed` (indigo for light, indigo-200 for dark)
- Segmented buttons, outlined buttons, filled buttons, snack bars, floating action button
- Bottom sheet for filter selection
- Status chips with semantic colors (dual-variant per theme)
- Responsive form layout
- Consistent 10-12px border radius across all components
- Themed card borders, dialog shapes, snackbar shapes, bottom sheet shapes

### Currency & Number Formatting
- **Default currency**: TND (Tunisian Dinar) — set in `AppConstants.defaultCurrency`
- **Decimal precision**: 3 digits after the decimal point (`AppConstants.currencyDecimals = 3`)
- **Dashboard summary cards**: Always display TND regardless of individual entry currencies
- **Statistics charts**: Axis labels and legends always display TND
- **PDF export summary**: Always displays TND
- **Individual entries**: Display their own currency (e.g. `150.000 USD`) in list views and recent entries

### Offline Support
- **Firestore persistence** enabled explicitly with unlimited cache size in `main.dart`
- **`ConnectivityService`** wraps `connectivity_plus` to monitor network status via `onConnectivityChanged` stream
- **`ConnectivityProvider`** exposes `isOnline` to the widget tree via Provider
- **`OfflineIndicator`** widget: orange banner shown at the top of Dashboard and All Records screens when offline
- Firestore automatically queues writes offline and syncs when reconnected
- Data reads served from local cache when offline
- **Offline-safe CRUD**: All save buttons (Add Entry, Edit Entry, Save Settings) use `try-catch-finally` — always navigate back or show error even when offline (Firestore queues writes locally)
- **Fallback caching**: Notification settings fall back to `SharedPreferences` if Firestore write fails

### Export to PDF
- **`PdfService`** generates landscape A4 PDF with `pdf` package
- **Table columns**: #, Person, Type, Amount, Currency, Status, Date, Deadline, Notes
- **Summary section**: Total entries, total borrowed/lent, pending/paid counts
- **Perspective-aware export**: accepts `currentUserId` — type and person name resolved via `entryTypeFor()` so the PDF matches the user's view
- **`PdfPreviewScreen`** shows live preview + share/print via `printing` package
- Export via **Dashboard hamburger menu** (exports all entries) and **All Records AppBar** (exports filtered entries)
- Empty state handling when no entries exist

### Export to CSV
- **`CsvService`** generates CSV with `csv` package (proper quoting for edge cases)
- **Headers**: #, Person, Type, Amount, Currency, Status, Date, Deadline, Notes
- **ISO date format**: `YYYY-MM-DD` for spreadsheet compatibility
- **Perspective-aware export**: accepts `currentUserId` — type and person name resolved via `entryTypeFor()` so the CSV matches the user's view
- **`CsvPreviewScreen`** shows DataTable preview + save to chosen location via `file_picker`
- Export via **Dashboard hamburger menu** (exports all entries) and **All Records AppBar** (exports filtered entries)
- User stays on preview screen after saving — can save multiple times to different locations

### Biometric App Lock (Optional)
- **`BiometricService`** wraps `local_auth` — checks hardware, enrollment, prompts biometric auth
- **`SecurityProvider`** manages app lock state, persists preference in `flutter_secure_storage`
- **Security**: Hamburger menu → Security — toggle app lock, shows device compatibility status
- **Lock gate in `main.dart`** — `_BiometricLockScreen` prompts authentication on app launch
- **`_AppLifecycleObserver`** — sits below `MultiProvider`, detects app pause/resume to lock
- **Pause-based locking** — sets `_pendingLock` on pause; only locks on resume if pending (avoids biometric dialog loop)
- **`_isAuthenticating` flag** — prevents `onAppPaused()` from setting pending lock during biometric prompt
- **Auto-disable** — if user removes biometrics after enabling lock, preference is cleared
- **Fallback** — `biometricOnly: false` allows device PIN/pattern as fallback
- **Android**: `USE_BIOMETRIC` permission + `FlutterFragmentActivity` (required by `local_auth`)
- **iOS**: `NSFaceIDUsageDescription` in Info.plist

### Dark Mode & Theme System
- **`ThemeProvider`** manages `ThemeMode` (light / dark / system) with `SharedPreferences` persistence
- **`AppTheme`** central accessor: `AppTheme.light` / `AppTheme.dark`
- **`AppColors`** semantic color tokens: `borrowColor`, `lendColor`, `paidLight/Dark`, `pendingLight/Dark`, `partialLight/Dark`, `overdueLight/Dark`, chart colors, stats colors, offline banner
- **Light theme**: `ColorScheme.fromSeed(seedColor: Color(0xFF3F51B5), brightness: light)`
- **Dark theme**: `ColorScheme.fromSeed(seedColor: Color(0xFF7986CB), brightness: dark)`
- **Theme-aware status colors**: `AppColors.forStatus(status, brightness)` returns appropriate variant per theme
- **All screens converted**: Zero hardcoded `Colors.*` in UI code (only `AppColors.*` tokens and intentional `Colors.white` on dark backgrounds)
- **Material 3 component themes**: `CardThemeData`, `InputDecorationTheme`, `ElevatedButtonThemeData`, `DialogThemeData`, `SnackBarThemeData`, `BottomSheetThemeData`, `ChipThemeData`, `SwitchThemeData`, `PopupMenuThemeData`
- **Chart readability**: All `fl_chart` axis labels and grid lines use `theme.colorScheme.onSurface` / `outlineVariant` for contrast
- **`AppearanceSettingsScreen`**: Hamburger menu → Appearance — System / Light / Dark radio selection with check indicator and current theme label
- **Persistence**: Saved as `'theme_mode'` key in `SharedPreferences`, loaded on app boot via `ThemeProvider.initialize()`
- **Default**: `ThemeMode.system` — follows device dark/light setting
- **Animations**: Flutter's built-in `themeAnimationDuration` handles smooth transitions

## Architecture

```
lib/
├── main.dart                          # App entry, providers, WorkManager init, first-run gate
├── firebase_options.dart              # Firebase config (generated)
├── models/
│   ├── user_model.dart                # User data model
│   ├── borrow_lend.dart               # Borrow/lend entry model + enums (EntryType, EntryStatus, ApprovalStatus)
│   ├── shared_entry_model.dart        # SharedEntry model with linked user fields + entryTypeFor()
│   ├── reminder_settings.dart         # Notification settings model
│   ├── pending_invite_model.dart      # PendingInvite model for user invitations
│   └── change_request.dart            # ChangeRequest model for edit proposals
├── theme/
│   ├── app_theme.dart                 # AppTheme accessor + AppColors semantic tokens
│   ├── light_theme.dart               # ThemeData for light mode
│   └── dark_theme.dart                # ThemeData for dark mode
├── services/
│   ├── auth_service.dart              # Firebase Auth operations + fetchAllUsers + searchUsers
│   ├── entry_service.dart             # Legacy Firestore CRUD (per-user sub-collection)
│   ├── shared_entry_service.dart      # Shared entries Firestore CRUD (ARRAY-CONTAINS query)
│   ├── notification_service.dart      # flutter_local_notifications + WorkManager scheduling
│   ├── notification_callback.dart     # Top-level WorkManager dispatcher (background isolate)
│   ├── connectivity_service.dart      # Monitors online/offline status via connectivity_plus
│   ├── pdf_service.dart               # PDF generation with table + summary
│   ├── csv_service.dart               # CSV generation with headers
│   ├── biometric_service.dart         # Biometric authentication via local_auth
│   ├── invite_service.dart            # Pending invite CRUD + token/code generation
│   └── change_request_service.dart    # Change request Firestore CRUD + real-time stream
├── providers/
│   ├── auth_provider.dart             # Auth state
│   ├── entry_provider.dart            # Legacy entry state (per-user sub-collection)
│   ├── shared_entry_provider.dart     # Shared entry state, filters, aggregates, editEntryFromMap
│   ├── notification_provider.dart     # Settings persistence, schedule logic, timer, _fireDue
│   ├── connectivity_provider.dart     # Exposes isOnline to the widget tree
│   ├── security_provider.dart         # App lock state, enable/disable, biometric auth
│   ├── theme_provider.dart            # ThemeMode persistence, cycle, current label
│   └── change_request_provider.dart   # Change request state, create/accept/reject/cancel
├── screens/
│   ├── auth_screen.dart               # Login / Sign up / Password reset
│   ├── dashboard_screen.dart          # Summary cards, grouped by person, nav with badge
│   ├── all_records_screen.dart        # Full list with actions & filters
│   ├── grouped_entries_screen.dart    # Entries grouped by person with expandable lists
│   ├── add_edit_entry_screen.dart     # Entry form with UserSearchField + invite integration
│   ├── pending_requests_screen.dart   # Debt approval + change request workflow (four sections)
│   ├── invite_preview_screen.dart     # QR code + invite code + share/copy
│   ├── notification_settings_screen.dart # Reminder config UI
│   ├── statistics_screen.dart         # Charts: monthly totals, payment status, debt history
│   ├── appearance_settings_screen.dart # Theme selection (System / Light / Dark)
│   ├── pdf_preview_screen.dart        # PDF preview + share/print
│   ├── csv_preview_screen.dart        # CSV preview + save to file
│   ├── security_settings_screen.dart  # Biometric app lock toggle + device status
│   └── home_screen.dart               # Simple welcome screen (unused in nav flow)
├── widgets/
│   ├── offline_indicator.dart         # Orange banner shown when offline
│   ├── user_picker.dart               # Multi-select user picker for shared entries
│   └── user_search_field.dart         # Smart searchable field with invite fallback
└── utils/
    └── constants.dart                 # App-wide constants (including pendingInvitesCollection)
```

## Foundation & Config
- Flutter SDK 3.35+, Dart 3.9+
- Null safety, `copyWith` / `toMap` / `fromMap` everywhere
- `coreLibraryDesugaring` enabled for `java.time` API on older Android
- `USE_EXACT_ALARM` + `SCHEDULE_EXACT_ALARM` + `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED` declared in `AndroidManifest.xml`
- `shared_preferences` for first-run tracking, theme mode persistence
- Firestore composite index on `shared_entries` (`participants` ASC + `createdAt` DESC)
- Firestore composite index on `change_requests` (`participants` ASC + `status` ASC + `createdAt` DESC)
- Firestore security rules for `shared_entries` (participants read, creator delete, participant update)
- Firestore security rules for `pending_invites` (authenticated read, creator CRUD)
- Firestore security rules for `change_requests` (participants read/write)
- Remote: `https://github.com/MaherCh9752/borrow-tracker.git`

## Pending
- Deep links for invite acceptance (invite preview screen only — no deep link handler yet)
- Background invite checking (invites expire silently — no notification to creator)

## Bug Fixes (July 2026)

### MIUI / Redmi 13C stability — platform channel timeouts (3 fixes)

**Problem:** On Xiaomi/Redmi devices running MIUI/HyperOS, several platform channel calls could hang indefinitely, causing:
- Infinite loading spinner at startup (app never reaches `runApp()` or stays stuck in `AuthWrapper`)
- First-run notification prompt never appearing on fresh install

---

### Fix 1: Timeouts on all platform-channel calls in main() + providers

**Files:** `lib/main.dart`, `lib/providers/security_provider.dart`, `lib/services/biometric_service.dart`

**Root cause:** `Firebase.initializeApp()`, `Workmanager().initialize()`, `local_auth.canCheckBiometrics`, `flutter_secure_storage.read()`, and `SharedPreferences.getInstance()` each make platform channel calls that can hang on MIUI. The code had zero timeouts, so a single hang blocked the app forever.

**Fixes:**
- `main()`: 10s timeout on `Firebase.initializeApp()`, 5s timeout on `Workmanager().initialize()`
- `SecurityProvider.initialize()`: 5s timeout on `_secureStorage.read()`, 5s timeout on `_biometricService.checkAvailability()`
- `BiometricService.checkAvailability()`: 4s timeout on `canCheckBiometrics` + 4s timeout on `getAvailableBiometrics()` with explicit `TimeoutException` handlers
- `FirstRunGate._check()`: 3s timeout on `SharedPreferences.getInstance()`

---

### Fix 2: Auth state fallback when authStateChanges stream never fires

**File:** `lib/providers/auth_provider.dart`

**Root cause:** `AuthProvider` relied entirely on the `FirebaseAuth.authStateChanges()` stream to determine auth status. If the stream never fired (e.g. platform channel hang on MIUI), `_status` stayed `AuthStatus.unknown` forever, keeping the loading spinner visible.

**Fix:**
- Check `FirebaseAuth.instance.currentUser` **synchronously** in the constructor — if a cached session exists, the user is immediately authenticated without waiting for the stream
- Added an 8-second fallback `Timer`: if the stream hasn't fired by then, forces `AuthStatus.unauthenticated` so the user at least sees the login screen
- Timer is cancelled if the stream fires normally

---

### Fix 3: First-run notification prompt — file-based persistence + widget-tree rendering

**File:** `lib/main.dart`

**Root cause (two issues):**
1. **`showDialog` + `addPostFrameCallback` unreliable on MIUI** — The dialog was scheduled via post-frame callback and rendered as a Navigator route. On MIUI, this timing could fail silently, and the dialog never appeared.
2. **SharedPreferences persistence crossing install boundaries** — MIUI's backup system ("MIUI optimization") can restore SharedPreferences data after uninstall/reinstall, making the app think the prompt was already shown.

**Fixes:**
- Replaced `showDialog` with a **full-screen widget** (`_NotificationPrompt`) rendered directly in the `build` method — no Navigator dependency
- Replaced `SharedPreferences`-based first-run detection with a **file-based flag** (`path_provider.getApplicationDocumentsDirectory() + .borrow_tracker_prompt` file) — survives app restarts but not MIUI backup restores
- Added `path_provider: ^2.1.0` to `pubspec.yaml`
- Still writes to `SharedPreferences` as a secondary record (for `notification_enabled_from_boot`)

---

### Fix 4: Removed empty android:taskAffinity in AndroidManifest.xml

**File:** `android/app/src/main/AndroidManifest.xml`

**Root cause:** Empty `android:taskAffinity=""` is non-standard and can cause unpredictable task-stack behavior on MIUI's custom task manager.

**Fix:** Removed the attribute entirely (defaults to the package name).

---

### Change request approval routing — wrong approver when linked user edits

**File:** `lib/providers/change_request_provider.dart:69`

**Root cause:** When creating a change request, `linkedUserId` was always set to `currentEntry.linkedUserId`. If the linked user (User B) edited an entry, the change request had `linkedUserId = User B`, making User B both the requester and the approver. The request never appeared in the creator's (User A) pending requests.

**Fix:** Determines the correct approver dynamically:
- If the **creator** edits → the **linked user** approves (`entry.linkedUserId`)
- If the **linked user** edits → the **creator** approves (`entry.createdBy`)

### Export CSV/PDF included pending approval entries

**Files:** `lib/screens/dashboard_screen.dart:402,415`

**Root cause:** Both export paths passed `sharedEntryProvider.entries` (all entries including pending approval) instead of `sharedEntryProvider.activeEntries` (only entries with `approvalStatus == ACTIVE`).

**Fix:** Changed both export calls to use `activeEntries`.

### Entry disappearing for other user after edit — 6 root causes fixed

1. **`_ApprovalCard._accept()`/`_reject()` full-document overwrite** (`pending_requests_screen.dart`): Changed to `editEntryFromMap()` which only writes `approvalStatus` and `updatedAt`, preserving the `participants` array that controls Firestore query visibility.

2. **`UserSearchField._clearSelection()` poison value** (`user_search_field.dart`): Changed `onSelected('')` to `onSelected(null)`. The empty string bypassed the null-aware `??` operator in the edit screen, corrupting `linkedUserId` in proposed changes.

3. **`_save()` rebuilds participants from scratch** (`add_edit_entry_screen.dart`): When editing, now preserves `widget.entry!.participants` instead of rebuilding from only the current user and search field selection.

4. **Provider error masking** (`shared_entry_provider.dart`): `addEntry()`, `editEntry()`, `deleteEntry()` now return `false` on error instead of `true`. Removed 500ms timeout that caused silent `TimeoutException` on slow connections.

5. **`_save()` catch block pops with success** (`add_edit_entry_screen.dart`): Error catch now shows an error snackbar instead of `Navigator.pop(context, true)` which masked failures.

6. **`SharedEntryProvider.editEntryFromMap()`** added to provider — partial-update method that delegates to `SharedEntryService.editEntryFromMap()`, used by approval accept/reject and change-request acceptance.
