# Borrow Tracker

A Flutter mobile app for tracking borrowed and lent money. Manage debts, set repayment deadlines, receive notifications (even when the app is killed), and keep a clear record of who owes whom.

---

## Features at a Glance

| Feature | Description |
|---------|-------------|
| **Authentication** | Email/password sign-up, sign-in, password reset, session persistence |
| **Dashboard** | Total borrowed/lent, pending count, upcoming deadlines, recent entries |
| **Entry CRUD** | Add, edit, delete, mark paid/partial/pending |
| **Search & Filters** | Name search, status, type, currency, deadline filters |
| **Notifications** | In-app + background delivery via WorkManager. Upcoming, due-today, overdue reminders at a configurable time. Even fires when the app is closed. |
| **Currencies** | 10 major currencies (USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, INR, MAD) |
| **Material 3** | Modern Material Design 3 with dynamic color scheme |

---

## Prerequisites

- Flutter SDK 3.35+ ([install guide](https://docs.flutter.dev/get-started/install))
- A Firebase project with **Authentication** (email/password) and **Cloud Firestore** enabled

---

## Firebase Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Create a project (or use an existing one)
3. Enable **Authentication** → **Sign-in method** → **Email/Password**
4. Enable **Cloud Firestore** → Create database in **test mode** (or configure security rules)
5. Register your app:
   - **Android**: Package name `com.borrowtracker.borrow_tracker`
   - **iOS**: Bundle ID `com.borrowtracker.borrowTracker`
6. Download config files:
   - `google-services.json` → place in `android/app/`
   - `GoogleService-Info.plist` → place in `ios/Runner/`
7. Run `flutterfire configure` (optional) or configure manually

---

## Getting Started

```bash
# Clone the repository
git clone https://github.com/MaherCh9752/borrow-tracker.git
cd borrow-tracker

# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build a release APK
flutter build apk --release
```

---

## Feature Tour

### 1. Authentication

| What to try | How |
|-------------|-----|
| **Sign Up** | Tap **Sign Up** → enter name, email, password → tap **Sign Up** |
| **Sign In** | Enter email + password → tap **Sign In** |
| **Password Reset** | Tap **Forgot Password?** → enter email → check inbox for reset link |
| **Validation** | Leave fields empty or enter an invalid email → see error messages |

When you sign up, a user document is created in Firestore at `users/{uid}`. The session persists across app restarts.

### 2. First-Run Notification Prompt

On the very first app launch (before you even sign in), a dialog asks:
> **Enable notifications to get reminded about upcoming deadlines and overdue payments.**

| Button | What happens |
|--------|-------------|
| **Enable** | OS notification permission + exact-alarm permission requested. After login, notification settings are auto-enabled |
| **Skip** | Dialog dismissed. You can enable later from the bell icon on the dashboard |

This dialog only appears **once per device** (tracked via `SharedPreferences`).

### 3. Dashboard

After signing in, the **Dashboard** shows:

| Card / Section | What it shows |
|----------------|---------------|
| **Total Borrowed** | Sum of all unpaid borrow entries (orange) |
| **Total Lent** | Sum of all unpaid lend entries (teal) |
| **Pending** | Count of entries with Pending status |
| **Deadlines (7d)** | Count of unpaid entries with deadlines in the next 7 days |
| **Recent Entries** | Last 5 entries with person name, amount, status chip, and relative time |

- Tap the **+** FAB → add a new entry
- Tap the **list icon** or **View All** → all records with search and filters
- Tap the **bell icon** → notification settings

### 4. Add / Edit Entry

Tap the **+** FAB on the dashboard:

| Field | What to enter |
|-------|---------------|
| Person Name | Required |
| Type | **I Borrowed** (I owe them) or **I Lent** (they owe me) |
| Amount | Required, must be > 0 |
| Currency | USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, INR, MAD |
| Status | Pending / Paid / Partial |
| Date | Defaults to today |
| Deadline | Optional due date |
| Notes | Optional |

Tap **Add Entry** → saved to Firestore → dashboard updates instantly.

To **edit**, navigate to **All Records** → tap the **⋮** menu → **Edit**.

### 5. All Records & Filters

Navigate via the **list icon** in the dashboard AppBar.

| Action | How |
|--------|-----|
| **Search** | Type a person's name in the search bar |
| **Filter by status** | Tap the status chip → pick Pending / Paid / Partial |
| **Filter by type** | Tap the type chip → pick I Borrowed / I Lent |
| **Filter by currency** | Tap the currency chip → pick a currency |
| **Filter by deadline** | Tap the deadline chip → pick Has deadline / No deadline / Overdue / Next 7 days |
| **Edit** | Tap the **⋮** menu → **Edit** |
| **Mark Paid / Pending** | Tap the **⋮** menu → toggle status instantly |
| **Mark Partial** | Tap the **⋮** menu → sets status to Partial |
| **Delete** | Tap the **⋮** menu → confirm deletion |

Active filters are highlighted in the app's primary color. Tap an active chip to clear it. The AppBar shows a clear-all icon when filters are active.

### 6. Notifications

The app has two delivery mechanisms so reminders fire **even when the app is closed**:

| Mechanism | When it fires |
|-----------|---------------|
| **In-app Timer** (every 5s) | While the app is open or in the background |
| **WorkManager** (JobScheduler) | Even if the app is killed. Android OS guarantees execution |

#### Notification types

| Type | When | Example |
|------|------|---------|
| **Upcoming Deadline** | X days before the due date (configurable: 1/3/7) | "John — $50 is due in 3 days" |
| **Due Today** | On the due date at the configured reminder time | "Jane — $120 is due today!" |
| **Overdue Reminder** | After the deadline passes (once or daily) | "Bob — $200 was due on 15/5/2026" |

#### Configure reminders

Tap the **bell icon** on the dashboard:

| Setting | What it does |
|---------|--------------|
| **Enable Notifications** | Master toggle |
| **Remind on day of deadline** | Fire at reminder time on the due date |
| **Upcoming Deadline Reminders** | Enable pre-due-date reminders |
| **Remind before** | 1 day / 3 days / 7 days before the deadline |
| **Overdue Reminders** | Enable reminders after the deadline passes |
| **Daily Overdue Reminder** | Repeat every day until the entry is marked paid |
| **Reminder Time** | Time of day for all reminders (default 09:00) |

Tap **Save Settings** → changes are persisted to Firestore and notifications reschedule automatically.

#### What to try

1. Add an entry with a deadline **a few minutes from now**
2. Set the reminder time to just before the deadline
3. Close the app completely (swipe from recents)
4. Wait — a notification should appear at the scheduled time
5. Reopen the app → mark the entry as Paid → the overdue reminders stop

> **Note**: On some Android OEMs (Xiaomi, Huawei, Samsung), you may need to disable battery optimization for the app in system settings to ensure timely WorkManager delivery.

### 7. Architecture Overview

```
lib/
├── main.dart                          # App entry, providers, WorkManager init, first-run gate
├── models/                            # Data models with Firestore serialization
├── services/                          # Firebase, notifications, WorkManager callback
├── providers/                         # ChangeNotifier state management
├── screens/                           # UI screens (auth, dashboard, records, settings)
└── utils/                             # Constants
```

| Layer | Technology |
|-------|-----------|
| UI | Flutter 3.35+ / Material 3 |
| Auth | Firebase Auth (email/password) |
| Database | Cloud Firestore (real-time streams) |
| State | Provider + ChangeNotifier |
| In-app notifications | flutter_local_notifications |
| Background notifications | workmanager (JobScheduler) |
| First-run tracking | shared_preferences |

---

## Project Status

See [PROJECT-STATE.md](PROJECT-STATE.md) for a detailed list of implemented and pending features.
