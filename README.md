# Borrow Tracker

A Flutter mobile app for tracking borrowed and lent money. Manage debts, set repayment deadlines, and keep a clear record of who owes whom.

## Features

- **Authentication** — Sign up, sign in, and password reset via Firebase Auth
- **Dashboard** — At-a-glance summary of total borrowed, total lent, pending repayments, and upcoming deadlines
- **Entry Management** — Add, edit, delete, and update status of borrow/lend records
- **Real-time Sync** — All data synced instantly via Cloud Firestore streams
- **Currencies** — Support for 10 major currencies (USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, INR, MAD)
- **Status Tracking** — Mark entries as Pending, Paid, or Partial
- **Deadlines** — Set optional repayment deadlines for each entry

---

## Prerequisites

- Flutter SDK 3.35+ ([install guide](https://docs.flutter.dev/get-started/install))
- A Firebase project with **Authentication** (email/password) and **Cloud Firestore** enabled

---

## Firebase Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Create a new project (or use an existing one)
3. Enable **Authentication** → **Sign-in method** → **Email/Password**
4. Enable **Cloud Firestore** → Create database in **test mode** (or configure security rules)
5. Register your app:
   - **Android**: Package name `com.borrowtracker.borrow_tracker`
   - **iOS**: Bundle ID `com.borrowtracker.borrowTracker`
6. Download the config files:
   - `google-services.json` → place in `android/app/`
   - `GoogleService-Info.plist` → place in `ios/Runner/`
7. Run `flutterfire configure` (optional, generates `lib/firebase_options.dart`) or configure manually

---

## Getting Started

```bash
# Clone the repository
git clone https://github.com/MaherCh9752/borrow-tracker.git
cd borrow-tracker

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## Feature Tour

### 1. Authentication
| Screen | What to try |
|--------|-------------|
| Sign In | Enter email + password → tap **Sign In** |
| Sign Up | Tap **Sign Up** → fill in name, email, password → tap **Sign Up** |
| Password Reset | Tap **Forgot Password?** → enter email → check inbox for reset link |
| Validation | Leave fields empty or enter an invalid email → see error messages |

When you sign up, a user document is created in Firestore at `users/{uid}`. The auth session persists across app restarts.

### 2. Dashboard
After signing in, the **Dashboard** shows:

| Card | Description |
|------|-------------|
| **Total Borrowed** | Sum of all unpaid borrow entries |
| **Total Lent** | Sum of all unpaid lend entries |
| **Pending** | Count of entries with Pending status |
| **Deadlines (7d)** | Count of unpaid entries with deadlines within the next 7 days |
| **Recent Entries** | Last 5 entries with person name, amount, status, and relative time |

- Tap the **+** FAB → add a new entry
- Tap the **list icon** in the AppBar → view all records
- Pull down to refresh

### 3. Add Entry
Tap the **+** FAB on the dashboard to open the add form:

| Field | What to enter |
|-------|---------------|
| Person Name | Name of the person (required) |
| Type | Toggle between **I Borrowed** (I owe them) or **I Lent** (they owe me) |
| Amount | Numeric value > 0 (required) |
| Currency | Select from 10 currencies |
| Status | Pending / Paid / Partial |
| Date | Date of the entry (defaults to today) |
| Deadline | Optional repayment due date |
| Notes | Any additional details (optional) |

Tap **Add Entry** → entry is saved to Firestore → dashboard updates automatically.

### 4. All Records
- Navigate via the **list icon** in the dashboard AppBar or **View All** in Recent Entries
- Each entry shows: person name, amount with sign (+/-), currency, deadline, and status chip
- Tap the **⋮** menu on any entry to:

| Action | Behavior |
|--------|----------|
| **Edit** | Opens the entry in edit mode with all fields pre-filled |
| **Mark Paid / Mark Pending** | Toggles the status instantly |
| **Mark Partial** | Sets status to Partial |
| **Delete** | Shows confirmation dialog → removes entry from Firestore |

Editing an entry updates Firestore in real time and the dashboard reflects changes immediately.

### 5. Search & Filters
Navigate to **All Records** via the list icon or View All link. At the top you'll find:

| Feature | How to use |
|---------|-----------|
| **Search bar** | Type any part of a person's name — results filter instantly |
| **Status chip** | Tap → pick Pending, Paid, or Partial from the bottom sheet |
| **Type chip** | Tap → pick I Borrowed or I Lent |
| **Currency chip** | Tap → pick from currencies you've used |
| **Deadline chip** | Tap → pick Has deadline / No deadline / Overdue / Next 7 days |

- Active chips are highlighted in the app's primary color
- Tap an already-active chip to clear that filter
- The AppBar shows a **clear all** icon when any filter is active
- When no entries match, a "Clear filters" button appears

### 6. Architecture Overview

```
lib/
├── main.dart                 # App entry, providers, auth routing
├── firebase_options.dart     # Firebase configuration
├── models/
│   ├── user_model.dart       # User data model
│   └── borrow_lend.dart      # Borrow/lend entry model with enums
├── services/
│   ├── auth_service.dart     # Firebase Auth operations
│   └── entry_service.dart    # Firestore CRUD operations
├── providers/
│   ├── auth_provider.dart    # Auth state management
│   └── entry_provider.dart   # Entry state, filters, computed aggregates
├── screens/
│   ├── auth_screen.dart      # Login/register UI
│   ├── home_screen.dart      # Legacy placeholder
│   ├── dashboard_screen.dart # Main dashboard with cards
│   ├── all_records_screen.dart # Full entry list with actions
│   └── add_edit_entry_screen.dart # Entry form
├── widgets/                  # Reusable widgets (future)
└── utils/
    └── constants.dart        # App-wide constants
```

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | Flutter 3.35+ / Dart 3.9+ |
| Authentication | Firebase Auth (email/password) |
| Database | Cloud Firestore (real-time) |
| State Management | Provider with ChangeNotifier |
| Architecture | Feature-based, services + providers + screens |

---

## Project Status

See [PROJECT-STATE.md](PROJECT-STATE.md) for detailed progress information.
