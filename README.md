# Borrow Tracker

A production-ready Flutter mobile app for tracking borrowed and lent money — with real-time sync, shared entries between users, debt linking with approval, edit proposals with change requests, and a polished Material 3 UI.

---

## Quick Start Walkthrough

These scenarios walk through the core workflows end-to-end.

### Scenario A: Both users already registered

1. **User A signs up** → enters name, email, password
2. **User A adds a shared entry** → taps **+**, searches for **User B**, enters amount "50 TND" as "I Lent", sets a deadline 3 days out, saves
3. **User B signs in** → sees a badge on the hamburger menu
4. **User B approves the entry** → hamburger menu → **Pending Requests** → **Accept**
5. **User A checks the dashboard** → sees the entry counted in totals
6. **User A edits the entry** → changes amount from 50 to 75 → **Submit for Approval**
7. **User B reviews & accepts** → **Pending Requests** → **Change Requests** → **Accept**
8. **Try exports** → hamburger menu → **Export to CSV** / **Export to PDF**
9. **Try notifications** → hamburger menu → **Notifications** → set a reminder time
10. **Try offline** → enable airplane mode → add/edit entries → disable airplane mode → everything syncs

### Scenario B: Inviting an unregistered user

1. **User A signs up** → enters name, email, password
2. **User A adds an entry for an unregistered user** → taps **+**, types "John" in the Person field → **No users found** appears
3. **User A creates an invite** → taps **Share Link** → fills amount, deadline, etc. → taps **Add Entry**
4. **Invite Preview** opens → copy the invite code (e.g. `XK7M2Q`)
5. **User A tracks the invite** → hamburger menu → **Pending Requests** → **Invites sent** — the invite is already there with Copy Code / Cancel actions
6. **Switch to User B's device** → open a fresh install of the app
7. **User B signs up with the invite code** → enters `XK7M2Q` in the **Invite Code** field, taps **Verify** → name autofills as "John"
8. **User B completes signup** → fills email + password → **Sign Up**
9. **User B approves the entry** → hamburger menu → **Pending Requests** → **Needs your approval** → **Accept**
10. **Both users see the entry** in their dashboard totals — User A's invite card disappears from Pending Requests automatically

> For a two-device test, install the app on two phones or use an emulator + physical device.

---

## Getting Started

### Prerequisites

- Flutter SDK 3.35+
- Dart SDK 3.9+
- A Firebase project with **Authentication** (email/password) and **Cloud Firestore** enabled
- Two devices or accounts to test shared features (optional but recommended)

### Installation

```bash
git clone https://github.com/MaherCh9752/borrow-tracker.git
cd borrow-tracker
flutter pub get
```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (email/password provider)
3. Enable **Cloud Firestore**
4. Deploy Firestore indexes, rules, and (if needed) the Firebase config:
   ```bash
   firebase deploy --only firestore:indexes,rules
   ```
5. Download `google-services.json` and place it in `android/app/`
6. (Optional) Download `GoogleService-Info.plist` for iOS and place it in `ios/Runner/`

> **Important:** Always deploy Firestore rules and indexes when pulling changes — the invite code lookup and entry linking depend on the latest security rules.
> ```bash
> firebase deploy --only firestore:rules,firestore:indexes
> ```

### Run

```bash
flutter run
```

---

## Feature Walkthrough

*Each section below is independent — jump to whatever interests you.*

### 1. Authentication

| Action | Steps |
|--------|-------|
| Sign up | Tap **Sign Up** → enter name, email, password → **Sign Up** |
| Sign in | Enter email + password → **Sign In** |
| Password reset | Tap **Forgot Password?** → enter email → check inbox |
| Session persistence | Kill and reopen the app → still signed in |

---

### 2. Adding Your First Entry

Tap the **+** FAB on the dashboard.

| Field | Required | Notes |
|-------|----------|-------|
| Person | Yes | Searchable — type to find registered users, or enter any name |
| Type | Yes | **I Borrowed** or **I Lent** (segmented button) |
| Amount | Yes | Must be > 0, supports 3 decimal places |
| Currency | Yes | TND (default), USD, EUR, GBP |
| Status | Yes | Pending / Paid / Partial (defaults to Pending) |
| Date | Yes | Defaults to today |
| Deadline | No | Used by notification reminders |
| Notes | No | Free text |

**Try this:**
- Add a borrow entry with a deadline 3 days from now
- Add a lend entry marked as Paid
- Edit any field and save — the list updates in real time

---

### 3. User Search & Debt Linking

The person name field is a smart search that finds registered users.

| Action | Steps |
|--------|-------|
| Search for a user | Type a name or email → suggestions appear after 2+ characters |
| Select a user | Tap a suggestion → field locks with the user's name |
| Clear selection | Tap the **X** button → field resets to search mode |
| No users found | Invite options appear (QR Code / Share Link) |

**Try this:**
1. Tap **+** to add an entry
2. In the **Person** field, type a name of a registered user
3. Select them from the dropdown — the field locks
4. Complete the form and save
5. The entry now links to that user's account

---

### 4. Debt Approval Workflow

When you link a debt to another user, it starts as **Pending Approval** and must be accepted before it counts in totals.

#### Creating a Linked Entry

1. Sign in as **User A**
2. Tap **+** → search and select **User B** in the Person field
3. Fill in amount, type, deadline, etc.
4. Tap **Add Entry**
5. The entry is created with `approvalStatus: PENDING_APPROVAL`

#### Accepting or Rejecting

1. Sign in as **User B**
2. Open the hamburger menu → **Pending Requests** (shows badge count)
3. Under **"Needs your approval"**, find the entry — it shows **"Created by User A"**
4. Tap **Accept** → entry becomes `ACTIVE` and appears in dashboard/statistics
5. Or tap **Reject** → entry is excluded from all calculations

#### Entry Type Inversion

When User A creates a "I Borrowed" entry linking to User B:
- User A sees it as **"I Borrowed"** with subtitle **"with User B"**
- User B sees it as **"I Lent"** with subtitle **"from User A"**

This applies everywhere — dashboard, all records, statistics, and CSV/PDF exports.

---

### 5. Editing Linked Entries (Change Requests)

When you edit a shared entry that links to another user, the change goes through an approval workflow instead of applying immediately.

#### Proposing an Edit

1. Open an entry for editing (tap an entry → edit)
2. Make your changes (amount, type, status, deadline, notes, etc.)
3. Tap **Submit for Approval**
4. A change request is created — the entry remains unchanged for the other user

#### Reviewing Edit Proposals

1. Sign in as the other user
2. Open hamburger menu → **Pending Requests**
3. Under **"Change requests"**, you'll see the proposed edit with a diff display showing exactly what changed
4. Tap **Accept** → changes are applied to the entry
5. Tap **Reject** → proposed changes are discarded

#### Cancelling an Edit

1. Open hamburger menu → **Pending Requests**
2. Under **"Your change requests"**, find the pending edit
3. Tap **Cancel Request** → the change request is removed

**Key behaviors:**
- The original entry remains unchanged while the edit is pending
- Only the specific fields in the proposed change are updated (participants array is always preserved)
- Both users see real-time updates via Firestore streams

---

### 6. User Invitation System

When you search for a user who isn't registered yet, you can invite them to join the app and automatically link entries.

#### Creating an Invite

1. Tap **+** to add an entry
2. Type a name in the Person field → **"No users found"**
3. Two buttons appear: **QR Code** and **Share Link**
4. Tap either → the entry will be saved first, then an invite is created
5. The **Invite Preview** screen opens showing:
   - **QR code** — scan to download the app
   - **Invite code** — 6-character uppercase code (e.g. `XK7M2Q`)
   - **Copy Code** button — copies to clipboard
   - **Share Invite** button — opens system share sheet with code + download link
6. Share the invite code with the new user via text, messaging, etc.

Invites expire in 7 days.

#### Tracking a Pending Invite

As soon as the entry + invite are saved, the invite is visible to the creator — no need to wait for the new user to register:

1. Open hamburger menu → **Pending Requests**
2. Under **"Invites sent"**, find the invite card showing:
   - The invited person's name
   - The invite code (tap **Copy Code** to resend it)
   - How many days remain until expiry
   - **Cancel** — deletes the invite and its linked entry (use this if you created it by mistake)
3. When the invited user signs up with the code, the card disappears automatically and the entry moves to the normal approval flow

#### Signing Up with an Invite Code

1. Open the app for the first time → **Sign Up** screen
2. An optional **Invite Code** field appears below the display name
3. Enter the code you received (e.g. `XK7M2Q`) and tap **Verify**
4. The code is validated — your display name is autofilled with the name the creator entered
5. You can change the name if desired
6. Complete signup (email + password) → account is created
7. **After signup**, the pending entry is automatically linked to your account:
   - The entry appears in **Pending Requests** → **Needs your approval**
   - You can **Accept** or **Reject** the entry
   - Once accepted, the entry counts in dashboard totals and statistics

#### Full End-to-End Flow

| Step | User A (Creator) | User B (Invited) |
|------|-----------------|-----------------|
| 1 | Adds entry for "John", taps Invite | |
| 2 | Shares invite code with John | |
| 3 | Sees invite in Pending Requests → **Invites sent** (copy/resend anytime) | |
| 4 | | Downloads app, signs up with invite code |
| 5 | | Name autofilled, completes signup |
| 6 | Invite card disappears after signup | Sees entry in Pending Requests → Accept |
| 7 | Sees entry confirmed on dashboard | Entry active in dashboard |

---

### 7. Dashboard

The first screen after sign-in.

| Element | What to look for |
|---------|-----------------|
| Total Borrowed card | Orange card — shows total in TND (active entries only) |
| Total Lent card | Teal card — shows total in TND (active entries only) |
| Net Balance card | Positive = others owe you, Negative = you owe others, Zero = settled |
| Pending count | Shows number of unpaid entries |
| Deadlines (7d) | Shows entries due in the next 7 days |
| By Person | Expandable cards for each linked person with avatar, lent/borrowed totals, net balance, next deadline |
| Pending Requests badge | Red badge on menu icon — counts approvals, change requests, and sent invites |

**Expandable person cards:** Tap any person card to expand and see individual entries sorted by deadline priority (overdue first, nearest first). Tap an entry to edit it. Color-coded deadline labels: red = overdue, orange = due within 3 days, gray = future.

---

### 8. Navigation — Hamburger Menu

All navigation is through the hamburger menu (≡) in the AppBar.

| Menu Item | Where it goes |
|-----------|--------------|
| All Records | Full list with search, filters, and actions |
| Grouped by Person | Entries grouped by linked person with expandable lists |
| Pending Requests | Debt approval workflow + sent invites (with badge count) |
| Statistics | Three interactive charts |
| Export to CSV | Preview and save CSV file |
| Export to PDF | Preview, share, or print PDF |
| Notifications | Reminder configuration |
| Appearance | Theme selection (Light / Dark / System) |
| Security | Biometric app lock settings |

---

### 9. Grouped by Person

Open via the hamburger menu → **Grouped by Person**.

| Element | What to look for |
|---------|-----------------|
| Person header | Avatar with initial, name, lent/borrowed totals, net balance, next deadline |
| Net balance | Positive (teal) = they owe you, Negative (orange) = you owe them |
| Expand/collapse | Tap a group to show/hide individual entries |
| Entry details | Amount, currency, status chip, date, deadline |

**Try this:**
1. Create entries with multiple people
2. Open Grouped by Person → see each person's section
3. Expand a person → see all entries with that person
4. Use search → groups filter by person name
5. Apply filters → groups update in real time

---

### 10. All Records & Filters

Open via the hamburger menu → **All Records**.

| Action | How |
|--------|-----|
| Search by name | Type in the search bar — filters as you type |
| Filter by status | Tap Status chip → select Pending / Paid / Partial |
| Filter by type | Tap Type chip → Borrowed / Lent (respects your perspective) |
| Filter by currency | Tap Currency chip → pick from used currencies |
| Filter by deadline | Tap Deadline chip → Has deadline / No deadline / Overdue / Next 7 days |
| Combine filters | Apply multiple at once — active chips are highlighted |
| Clear all | Tap the clear icon in the AppBar |
| Edit entry | Tap **⋮** → Edit |
| Change status | Tap **⋮** → Mark Paid / Mark Pending / Mark Partial |
| Delete entry | Tap **⋮** → Delete → confirm (only if you're the creator) |

**Due date sorting:** Entries are automatically sorted by deadline priority:
1. **Overdue** debts appear first (past deadline, unpaid)
2. **Nearest deadline** — entries due soonest come next
3. **Future deadline** — entries further out
4. **No deadline** — entries without a deadline appear last
5. **Paid entries** are pushed to the end within each tier

---

### 11. Statistics

Open via the hamburger menu → **Statistics**.

| Chart | What it shows |
|-------|--------------|
| Monthly Totals | Grouped bar chart — orange = borrowed, teal = lent per month |
| Payment Status | Pie chart — green = paid, orange = unpaid with percentages |
| Debt History | Curved line chart — net cumulative debt over time |

All charts respect entry type inversion — each user sees entries from their own perspective.

---

### 12. Notifications

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

**Behavior notes:**
- Notifications only fire for **confirmed entries** (`ApprovalStatus: ACTIVE`) — entries waiting for the other user's approval are excluded
- Notifications are **per-device per-user** — signing out cancels all scheduled notifications for the previous user

**Test background notifications:**
1. Add an entry with a deadline a few minutes from now
2. Confirm the entry on both ends (if shared)
3. Set the reminder time just before that deadline
4. Close the app completely
5. Wait — the notification appears at the scheduled time
6. Reopen → mark as Paid → overdue reminders stop

**Test user isolation (multi-user on same device):**
1. Sign in as User A → set up notifications with an upcoming deadline
2. Sign out → sign in as User B on the same device
3. Only User B's entries trigger notifications — User A's scheduled alarms are cancelled

> On some Android devices, disable battery optimization for reliable background delivery.

---

### 13. Offline Support

The app works fully offline. Firestore queues all changes locally and syncs when reconnected.

| Test | Steps |
|------|-------|
| Offline indicator | Turn on airplane mode → orange banner appears |
| Add entry offline | With airplane mode on → tap + → fill form → save → navigates back |
| Edit entry offline | With airplane mode on → edit an entry → save |
| Sync on reconnect | Turn off airplane mode → all changes appear in Firestore |
| Cached reads | Airplane mode on → navigate the app → entries still load |

---

### 14. Export to PDF

Open via the hamburger menu → **Export to PDF**.

| Action | How |
|--------|-----|
| Preview | Full-page landscape A4 PDF preview |
| Share | Tap share icon → send via email, messaging, etc. |
| Print | Tap print icon → send to a printer |
| Filtered export | From All Records, apply filters first → then export |

**PDF includes:** header, table (Person, Type, Amount, Currency, Status, Date, Deadline, Notes), alternating row colors, summary section with TND totals, page numbers. Type and person name are resolved from your perspective.

---

### 15. Export to CSV

Open via the hamburger menu → **Export to CSV**.

| Action | How |
|--------|-----|
| Preview | DataTable preview of all entries |
| Save | Tap save icon → choose folder → file saves |
| Save again | Stay on preview → save to a different location |
| Filtered export | From All Records, apply filters first → then export |

**CSV includes:** headers, ISO dates (YYYY-MM-DD), proper quoting for commas, 3 decimal places for amounts. Type and person name are resolved from your perspective.

---

### 16. Dark Mode

Open via the hamburger menu → **Appearance**.

| Option | Behavior |
|--------|----------|
| System (default) | Follows your device's dark/light setting |
| Light | Always uses the light theme |
| Dark | Always uses the dark theme |

Toggle between modes → all screens update instantly. Theme preference persists across app restarts.

---

### 17. Biometric App Lock

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
├── models/                            # Data models (BorrowLend, SharedEntry, User, ReminderSettings, PendingInvite, ChangeRequest)
├── theme/                             # AppTheme, AppColors, light/dark ThemeData
├── services/                          # Firebase Auth, Firestore CRUD, Notifications, PDF, CSV, Biometric, Invite, ChangeRequest
├── providers/                         # Auth, Entry, SharedEntry, Notification, Connectivity, Security, Theme, ChangeRequest
├── screens/                           # All UI screens
├── widgets/                           # Reusable widgets (OfflineIndicator, UserPicker, UserSearchField)
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
| QR Codes | qr_flutter |
| Sharing | share_plus |
| Biometrics | local_auth + flutter_secure_storage |
| Persistence | shared_preferences (theme) + path_provider (first-run flag) |

---

## Project Status

All planned features are implemented and verified. See [PROJECT-STATE.md](PROJECT-STATE.md) for the detailed feature list, architecture, and bug-fix changelog.

---

## License

This project is private and not open for contributions.
