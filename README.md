# Borrow Tracker

Track borrowed and lent money, set repayment deadlines, get notifications, and visualize your debt trends — all with real-time sync and offline-first storage.

---

## Stack

| Layer | What it uses |
|-------|-------------|
| UI | Flutter 3.35+ / Material 3 |
| Auth | Firebase Auth (email/password) |
| Database | Cloud Firestore (real-time streams) |
| State | Provider + ChangeNotifier |
| Charts | fl_chart |
| Notifications | flutter_local_notifications + WorkManager |
| First-run tracking | shared_preferences |
| Offline detection | connectivity_plus |
| PDF Export | pdf + printing |
| CSV Export | csv + file_picker |

---

## Setup

```bash
git clone https://github.com/MaherCh9752/borrow-tracker.git
cd borrow-tracker
flutter pub get
flutter run
```

Requires a Firebase project with **Authentication** (email/password) and **Cloud Firestore** enabled. Place `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS) in the respective platform folders.

---

## Feature Tour — How to Try Everything

### 1. Authentication

| What to try | Steps |
|-------------|-------|
| **Sign up** | Tap **Sign Up** → enter name, email, password → tap **Sign Up** |
| **Sign in** | Enter email + password → tap **Sign In** |
| **Password reset** | Tap **Forgot Password?** → enter email → check inbox |
| **Validation** | Leave fields empty or enter an invalid email → error messages appear |
| **Session persistence** | Kill the app and reopen → you're still signed in |

### 2. First-Run Notification Prompt

On the very first launch (before sign-in), a dialog asks to enable notifications.

- Tap **Enable** → OS permission dialogs appear → after login, notifications are auto-activated
- Tap **Skip** → you can enable later from the dashboard bell icon
- This dialog only shows **once per device**

### 3. Dashboard

The first screen after sign-in. Try:

| What to look for | How to trigger |
|-----------------|----------------|
| **Total Borrowed / Lent** | Add entries → the orange and teal cards update automatically |
| **Pending / 7-day deadlines count** | Add entries with different statuses and deadlines |
| **Recent Entries** | Last 5 entries shown with name, amount, status chip |
| **Pull to refresh** | Swipe down on the list |
| **Empty state** | Delete all entries → see the "No entries yet" message |

**Navigation buttons** in the AppBar:

| Icon | Where it goes |
|------|--------------|
| 📋 List | All Records (search / filter / edit / delete) |
| 📊 Bar chart | Statistics (three charts) |
| 🔔 Bell | Notification settings |
| 🚪 Sign out | Signs you out |

Tap the **+** FAB to add your first entry.

### 4. Add / Edit Entry

Tap the **+** FAB or the **⋮** menu → **Edit** on any entry.

| Field | What to enter | Notes |
|-------|--------------|-------|
| Person Name | Required | Free text |
| Type | **I Borrowed** or **I Lent** | Toggle via segmented button |
| Amount | Required | Must be > 0 |
| Currency | Pick from 10 currencies | USD, EUR, GBP, JPY, etc. |
| Status | Pending / Paid / Partial | Defaults to Pending |
| Date | Entry date | Defaults to today |
| Deadline | Optional due date | Used by notifications |
| Notes | Optional | Free text |

Try:
- Add a **borrow** entry with a deadline 3 days from now
- Add a **lend** entry marked as **Paid**
- Add an entry with no deadline and a note
- Edit any field and save → the list updates in real time

### 5. All Records & Filters

Tap the **list icon** in the dashboard AppBar.

| What to try | Steps |
|-------------|-------|
| **Search by name** | Type in the search bar → list filters as you type (case-insensitive) |
| **Filter by status** | Tap **Pending / Paid / Partial** chip → select a status |
| **Filter by type** | Tap **Borrowed / Lent** chip |
| **Filter by currency** | Tap a currency chip |
| **Filter by deadline** | Tap **Has deadline / No deadline / Overdue / Next 7 days** |
| **Combine filters** | Apply multiple filters at once → active chips are highlighted |
| **Clear filters** | Tap the **clear all** icon in the AppBar |
| **Edit** | Tap **⋮** → **Edit** |
| **Mark Paid / Pending / Partial** | Tap **⋮** → pick status → updates instantly |
| **Delete** | Tap **⋮** → **Delete** → confirm |

Distinct empty states show based on whether filters are active or there are truly no entries.

### 6. Statistics (Charts)

Tap the **bar chart icon** in the dashboard AppBar.

| Chart | What it shows | What to try |
|-------|--------------|-------------|
| **Monthly Totals** | Orange bars = borrowed, teal bars = lent per month | Add entries in different months → bars appear per month |
| **Payment Status** | Green = paid amount, orange = unpaid amount with % | Mark entries as paid → the pie shifts |
| **Debt History** | Line chart of net cumulative debt over time | Add borrow entries → line goes up; add lend entries → line goes down |

Edge cases to test:
- Empty state → "Add some entries to see statistics."
- Single entry → pie shows 100% one color, line shows a flat line
- Entries spanning multiple months → bar chart groups by month
- All entries paid → pie is 100% green

### 7. Notifications

Tap the **bell icon** in the dashboard AppBar to configure.

| Setting | What it does |
|---------|-------------|
| **Enable Notifications** | Master toggle for all reminders |
| **Remind on day of deadline** | Fires notification at the reminder time on the due date |
| **Upcoming Deadline Reminders** | Remind X days before the deadline |
| **Remind before** | Choose 1 / 3 / 7 days before |
| **Overdue Reminders** | Enable after a deadline passes |
| **Daily Overdue Reminder** | Repeat daily until marked paid |
| **Reminder Time** | Time of day for all notifications (default 09:00) |

**How to test background notifications:**

1. Add an entry with a deadline **a few minutes from now**
2. Set the reminder time to just before that deadline
3. Close the app completely (swipe from recents)
4. Wait — the notification appears at the scheduled time
5. Reopen the app → mark the entry as **Paid** → overdue reminders stop

> On some Android OEMs (Xiaomi, Huawei, Samsung), disable battery optimization for the app in system settings for reliable WorkManager delivery.

### 8. Offline Support

The app works fully offline — Firestore queues all changes locally and syncs when reconnected.

| What to try | Steps |
|-------------|-------|
| **Offline indicator** | Turn on airplane mode → orange banner appears at top of Dashboard and All Records |
| **Add entry offline** | With airplane mode on, tap **+** → fill form → tap **Add Entry** → navigates back instantly |
| **Edit entry offline** | With airplane mode on, tap **⋮** → **Edit** → change fields → save → navigates back |
| **Save settings offline** | With airplane mode on, open Notification Settings → toggle → save → navigates back |
| **Sync on reconnect** | Turn off airplane mode → all queued changes appear in Firestore automatically |
| **Cached reads** | Turn on airplane mode → navigate the app → all entries still load from local cache |

> All save operations use a 500ms timeout — if Firestore doesn't respond, the write is still queued locally and the app navigates back immediately.

### 9. Export to PDF

Tap the **PDF icon** in the Dashboard or All Records AppBar.

| What to try | Steps |
|-------------|-------|
| **Export all entries** | From Dashboard, tap the PDF icon → preview screen opens |
| **Export filtered entries** | From All Records, apply filters → tap PDF icon → only filtered entries appear |
| **Preview** | Full-page PDF preview with landscape A4 layout |
| **Share** | Tap the share icon → share via email, messaging, etc. |
| **Print** | Tap the print icon → send to a printer |

**PDF includes:**
- Header with app name and export date
- Table with columns: #, Person, Type, Amount, Currency, Status, Date, Deadline, Notes
- Alternating row colors for readability
- Summary section: total entries, borrowed/lent totals, pending/paid counts
- Page numbers in footer

### 10. Export to CSV

Tap the **table icon** in the Dashboard or All Records AppBar.

| What to try | Steps |
|-------------|-------|
| **Preview** | Tap the table icon → DataTable preview opens with all entries |
| **Export all entries** | From Dashboard, tap the table icon → preview shows all entries |
| **Export filtered entries** | From All Records, apply filters → tap table icon → only filtered entries appear |
| **Save to file** | Tap the save icon (AppBar) → system file picker opens → choose folder → file saves |
| **Save again** | After saving, you stay on the preview → tap save icon again to save to a different location |
| **Overwrite** | Save to the same location → overwrites the existing file |

**CSV includes:**
- Headers: #, Person, Type, Amount, Currency, Status, Date, Deadline, Notes
- ISO date format (`YYYY-MM-DD`) for spreadsheet compatibility
- Proper quoting for values containing commas

---

## Project Status

See [PROJECT-STATE.md](PROJECT-STATE.md) for the detailed feature list and pending work.
