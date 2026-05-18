# Borrow Tracker Project State

## Goal
Flutter mobile app for tracking borrowed and lent money.

## Stack
- Flutter 3.35+
- Firebase Auth (email/password)
- Cloud Firestore
- Provider state management

## Implemented Features

### Project Foundation
- Flutter project scaffolded with feature-based folder structure
- `lib/` organized into: `models/`, `services/`, `providers/`, `screens/`, `widgets/`, `utils/`
- MultiProvider setup with AuthProvider and EntryProvider at app root
- Firebase Core initialized on startup with AuthWrapper routing

### Authentication (`lib/services/auth_service.dart`, `lib/providers/auth_provider.dart`, `lib/screens/auth_screen.dart`)
- Email/password sign-up with display name
- Email/password sign-in
- Password reset via email
- Auth state persistence (session restored on cold start)
- Form validation (required fields, email format, password length)
- Error handling with user-friendly messages mapped from FirebaseAuthException codes
- Sign-out from dashboard AppBar

### Data Model (`lib/models/borrow_lend.dart`)
- `BorrowLend` model with fields: id, personName, amount, currency, type (borrow/lend), notes, createdAt, deadline, status (pending/paid/partial)
- `EntryType` enum: borrow, lend
- `EntryStatus` enum: pending, paid, partial
- Firestore serialization methods (`toMap`, `fromMap`, `copyWith`)

### CRUD Service (`lib/services/entry_service.dart`)
- Firestore structure: `users/{userId}/borrowLendEntries/{entryId}`
- `addEntry` — creates document with auto-ID, returns model with generated ID
- `editEntry` — updates document by entry.id
- `deleteEntry` — deletes document by entryId
- `fetchEntries` — real-time stream ordered by createdAt descending, uses `doc.id` for entry ID

### Entry Provider (`lib/providers/entry_provider.dart`)
- Real-time Firestore stream subscription with auto-refresh
- Computed aggregates: totalBorrowed, totalLent, pendingCount, upcomingDeadlineCount, recentEntries
- Proxy methods for add/edit/delete with boolean return and error capture
- Loading and error states exposed to UI

### Dashboard (`lib/screens/dashboard_screen.dart`)
- Summary cards: Total Borrowed (orange), Total Lent (teal)
- Stats cards: Pending count, Upcoming deadlines (next 7 days)
- Recent entries list (last 5) with person name, amount, status chip, relative time
- Empty state with guidance message
- Pull-to-refresh
- FloatingActionButton (+) to add new entry
- AppBar: list icon → AllRecordsScreen, logout button

### All Records Screen (`lib/screens/all_records_screen.dart`)
- Scrollable list of all entries
- Each entry shows: person name, amount with currency, deadline date, status chip
- PopupMenu (⋮) per entry with actions:
  - Edit → opens AddEditEntryScreen in edit mode
  - Mark Paid / Mark Pending — instant status toggle
  - Mark Partial — set status to partial
  - Delete — confirmation dialog, then removes from Firestore

### Search & Filters (`lib/providers/entry_provider.dart`, `lib/screens/all_records_screen.dart`)
- Text search by person name (case-insensitive, client-side)
- Status filter (Pending / Paid / Partial)
- Type filter (Borrowed / Lent)
- Currency filter (dynamically populated from user's used currencies)
- Deadline filter (Has deadline / No deadline / Overdue / Next 7 days)
- Filters toggle on/off via bottom sheet picker
- Active filters highlighted with primary color
- Filter count indicator in AppBar
- Clear all filters button
- Distinct empty states: "no entries" vs "no matches"

### Add/Edit Entry Screen (`lib/screens/add_edit_entry_screen.dart`)
- Person Name (TextFormField, required)
- Type toggle (SegmentedButton: I Borrowed / I Lent)
- Amount (numeric input, required, must be > 0)
- Currency dropdown (10 currencies: USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, INR, MAD)
- Status dropdown (Pending / Paid / Partial)
- Creation Date (DatePicker, defaults to now)
- Deadline (DatePicker, optional, clearable)
- Notes (multiline TextFormField, optional)
- Form validation on all required fields
- Save/Update button with loading indicator
- Auto-navigation back on success

### User Model (`lib/models/user_model.dart`)
- Fields: uid, email, displayName, createdAt
- `fromMap`/`toMap` for Firestore serialization

### Auth Service (`lib/services/auth_service.dart`)
- signInWithEmail, signUpWithEmail, signOut, sendPasswordResetEmail
- Error mapping from FirebaseAuthException codes to user-friendly messages
- Automatic user document creation in Firestore on first sign-in

## Architecture
- Feature-based folder structure
- Provider state management with ChangeNotifier
- Services layer handles Firebase operations
- Providers bridge services to UI with loading/error states
- Screens are consumer/presentation layer only

## Pending Features
- <s>Authentication</s>
- <s>CRUD entries</s>
- <s>Dashboard</s>
- <s>Search & Filters</s>
- Notifications
- Statistics
- Offline support
- Export
- Security
