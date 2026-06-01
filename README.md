# Borrow Tracker

A production-ready Flutter mobile app for tracking borrowed and lent money — with real-time sync, local notifications, offline support, and a polished Material 3 UI.

---

## Features at a Glance

| Feature | Description |
|---------|-------------|
| Authentication | Email/password sign-up, sign-in, password reset |
| Entry Management | Full CRUD with real-time Firestore sync |
| Dashboard | Summary cards, stats, recent entries |
| Search & Filters | Text search, status/type/currency/deadline filters |
| Notifications | In-app + background reminders for deadlines |
| Statistics | Bar, pie, and line charts via fl_chart |
| Dark Mode | Light / Dark / System theme with persistence |
| Offline Support | Full offline CRUD with automatic sync |
| PDF Export | Landscape A4 table with summary |
| CSV Export | Spreadsheet-ready data with file picker |
| Biometric Lock | Optional fingerprint/face authentication |

---

## Setup

### Prerequisites
- Flutter SDK 3.35+
- Dart SDK 3.9+
- A Firebase project with **Authentication** and **Cloud Firestore** enabled

### Installation

```bash
git clone https://github.com/MaherCh9752/borrow-tracker.git
cd borrow-tracker
flutter pub get
```

### Firebase Configuration

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (email/password provider)
3. Enable **Cloud Firestore**
4. Download `google-services.json` and place it in `android/app/`
5. (Optional) Download `GoogleService-Info.plist` for iOS and place it in `ios/Runner/`

### Run

```bash
flutter run
```

---

## How to Try Every Feature

### 1. Authentication

| Action | Steps |
|--------|-------|
| Sign up | Tap **Sign Up** → enter name, email, password → **Sign Up** |
| Sign in | Enter email + password → **Sign In** |
| Password reset | Tap **Forgot Password?** → enter email → check inbox |
| Form validation | Leave fields empty or enter invalid email → errors appear |
| Session persistence | Kill and reopen the app → still signed in |

---

### 2. First-Run Notification Prompt

On the very first launch (before sign-in), a dialog asks to enable notifications.

- **Enable** → OS permission dialogs appear → after login, notifications are auto-activated
- **Skip** → enable later from the dashboard menu
- This dialog only shows **once per device**

---

### 3. Dashboard

The first screen after sign-in.

| Element | What to look for |
|---------|-----------------|
| Total Borrowed card | Orange card — updates as you add borrow entries |
| Total Lent card | Teal card — updates as you add lend entries |
| Pending count | Shows number of unpaid entries |
| Deadlines (7d) | Shows entries due in the next 7 days |
| Recent Entries | Last 5 entries with name, amount, status chip, and relative time |
| Pull to refresh | Swipe down to reload from Firestore |

Tap the **+** FAB to add your first entry.

---

### 4. Navigation — Hamburger Menu

The dashboard uses a clean hamburger menu for navigation:

```
┌──────────────────────────────────────────┐
│  ☰    💰 Borrow Tracker            🚪  │
│ menu   logo + title                  logout│
└──────────────────────────────────────────┘
```

| Menu Item | Icon | Where it goes |
|-----------|------|--------------|
| All Records | 📋 | Full list with search, filters, and actions |
| Statistics | 📊 | Three interactive charts |
| Export to CSV | 📊 | Preview and save CSV file |
| Export to PDF | 📄 | Preview, share, or print PDF |
| Notifications | 🔔 | Reminder configuration |
| Appearance | 🎨 | Theme selection (Light / Dark / System) |
| Security | 🛡️ | Biometric app lock settings |

---

### 5. Add / Edit Entry

Tap the **+** FAB on the dashboard.

| Field | Required | Notes |
|-------|----------|-------|
| Person Name | Yes | Free text |
| Type | Yes | **I Borrowed** or **I Lent** (segmented button) |
| Amount | Yes | Must be > 0 |
| Currency | Yes | USD, EUR, GBP, TND |
| Status | Yes | Pending / Paid / Partial (defaults to Pending) |
| Date | Yes | Defaults to today |
| Deadline | No | Used by notification reminders |
| Notes | No | Free text |

**Try this:**
- Add a borrow entry with a deadline 3 days from now
- Add a lend entry marked as Paid
- Edit any field and save — the list updates in real time

---

### 6. All Records & Filters

Open via the hamburger menu → **All Records**.

| Action | How |
|--------|-----|
| Search by name | Type in the search bar — filters as you type |
| Filter by status | Tap Status chip → select Pending / Paid / Partial |
| Filter by type | Tap Type chip → Borrowed / Lent |
| Filter by currency | Tap Currency chip → pick from used currencies |
| Filter by deadline | Tap Deadline chip → Has deadline / No deadline / Overdue / Next 7 days |
| Combine filters | Apply multiple at once — active chips are highlighted |
| Clear all | Tap the clear icon in the AppBar |
| Edit entry | Tap **⋮** → Edit |
| Change status | Tap **⋮** → Mark Paid / Mark Pending / Mark Partial |
| Delete entry | Tap **⋮** → Delete → confirm |

---

### 7. Statistics

Open via the hamburger menu → **Statistics**.

| Chart | What it shows |
|-------|--------------|
| Monthly Totals | Grouped bar chart — orange = borrowed, teal = lent per month |
| Payment Status | Pie chart — green = paid, orange = unpaid with percentages |
| Debt History | Curved line chart — net cumulative debt over time |

**Edge cases:**
- Empty state → "Add some entries to see statistics."
- Single entry → pie shows 100% one color, line is flat
- All entries paid → pie is 100% green

---

### 8. Notifications

Open via the hamburger menu → **Notifications**.

| Setting | What it does |
|---------|-------------|
| Enable Notifications | Master toggle for all reminders |
| Remind on day of deadline | Fires at the reminder time on the due date |
| Upcoming Deadline Reminders | Remind X days before the deadline |
| Remind before | Choose 1 / 3 / 7 days |
| Overdue Reminders | Enable after a deadline passes |
| Daily Overdue Reminder | Repeat daily until marked paid |
| Reminder Time | Time of day for notifications (default 09:00) |

**Test background notifications:**
1. Add an entry with a deadline a few minutes from now
2. Set the reminder time just before that deadline
3. Close the app completely
4. Wait — the notification appears at the scheduled time
5. Reopen → mark as Paid → overdue reminders stop

> On some Android devices, disable battery optimization for reliable background delivery.

---

### 9. Offline Support

The app works fully offline. Firestore queues all changes locally and syncs when reconnected.

| Test | Steps |
|------|-------|
| Offline indicator | Turn on airplane mode → orange banner appears |
| Add entry offline | With airplane mode on → tap + → fill form → save → navigates back |
| Edit entry offline | With airplane mode on → edit an entry → save |
| Sync on reconnect | Turn off airplane mode → all changes appear in Firestore |
| Cached reads | Airplane mode on → navigate the app → entries still load |

> All save operations use a 500ms timeout — writes are queued locally even when offline.

---

### 10. Export to PDF

Open via the hamburger menu → **Export to PDF**.

| Action | How |
|--------|-----|
| Preview | Full-page landscape A4 PDF preview |
| Share | Tap share icon → send via email, messaging, etc. |
| Print | Tap print icon → send to a printer |
| Filtered export | From All Records, apply filters first → then export |

**PDF includes:** header, table (Person, Type, Amount, Currency, Status, Date, Deadline, Notes), alternating row colors, summary section, page numbers.

---

### 11. Export to CSV

Open via the hamburger menu → **Export to CSV**.

| Action | How |
|--------|-----|
| Preview | DataTable preview of all entries |
| Save | Tap save icon → choose folder → file saves |
| Save again | Stay on preview → save to a different location |
| Filtered export | From All Records, apply filters first → then export |

**CSV includes:** headers, ISO dates (YYYY-MM-DD), proper quoting for commas.

---

### 12. Dark Mode

Open via the hamburger menu → **Appearance**.

| Option | Behavior |
|--------|----------|
| System (default) | Follows your device's dark/light setting |
| Light | Always uses the light theme |
| Dark | Always uses the dark theme |

**Try this:**
- Toggle between modes → all screens update instantly
- Check charts, dialogs, snackbars, and status chips in both themes
- Kill and reopen → theme preference persists

---

### 13. Biometric App Lock

Open via the hamburger menu → **Security**.

| Action | Steps |
|--------|-------|
| Enable lock | Tap toggle → biometric prompt → authenticate → active |
| Disable lock | Tap toggle → authenticate → removed |
| App launch | With lock enabled, kill and reopen → biometric prompt |
| Background resume | Switch apps → return → lock screen appears |
| Fallback | Use device PIN/pattern if biometrics fail |

> Requires `FlutterFragmentActivity` on Android and biometric hardware + enrollment on the device.

---

## Architecture

```
lib/
├── main.dart                          # Entry point, providers, WorkManager init
├── firebase_options.dart              # Firebase config (generated)
├── models/                            # Data models (BorrowLend, User, ReminderSettings)
├── theme/                             # AppTheme, AppColors, light/dark ThemeData
├── services/                          # Firebase Auth, Firestore CRUD, Notifications, PDF, CSV, Biometric
├── providers/                         # Auth, Entry, Notification, Connectivity, Security, Theme
├── screens/                           # All UI screens
├── widgets/                           # Reusable widgets (OfflineIndicator)
└── utils/                             # Constants
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.35+ / Dart 3.9+ |
| UI | Material 3 with light/dark themes |
| Auth | Firebase Auth (email/password) |
| Database | Cloud Firestore (real-time streams) |
| State | Provider + ChangeNotifier |
| Charts | fl_chart 0.69+ |
| Notifications | flutter_local_notifications + WorkManager |
| Offline | Firestore persistence + connectivity_plus |
| PDF | pdf + printing |
| CSV | csv + file_picker |
| Biometrics | local_auth + flutter_secure_storage |
| Persistence | shared_preferences (theme, first-run flags) |

---

## Project Status

All planned features are implemented and verified. See [PROJECT-STATE.md](PROJECT-STATE.md) for the detailed feature list and architecture.

---

## License

This project is private and not open for contributions.
