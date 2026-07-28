import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'providers/auth_provider.dart';
import 'providers/change_request_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/entry_provider.dart';
import 'providers/shared_entry_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/security_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/notification_callback.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Platform channel calls (Firebase, WorkManager, etc.) can hang
  // indefinitely on some devices (e.g. Redmi 13C / MIUI).  Wrap each
  // in a timeout so the app always reaches runApp().
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Main] Firebase init failed or timed out: $e');
  }

  // Enable Firestore offline persistence (default on mobile, explicit for clarity).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  try {
    await Workmanager()
        .initialize(notificationCallbackDispatcher)
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('[Main] WorkManager init failed or timed out: $e');
  }
  runApp(const BorrowTrackerApp());
}

class BorrowTrackerApp extends StatelessWidget {
  const BorrowTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EntryProvider()),
        ChangeNotifierProvider(create: (_) => SharedEntryProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ChangeRequestProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: const _AppLifecycleObserver(child: FirstRunGate()),
          );
        },
      ),
    );
  }
}

class FirstRunGate extends StatefulWidget {
  const FirstRunGate({super.key});

  @override
  State<FirstRunGate> createState() => _FirstRunGateState();
}

class _FirstRunGateState extends State<FirstRunGate> {
  bool _checking = true;
  bool _showPrompt = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  /// Returns the app's persistent directory for storing first-run flags.
  /// Falls back to a temp directory if unavailable.
  Future<Directory> _storageDir() async {
    try {
      final paths = await getApplicationDocumentsDirectory();
      return paths;
    } catch (_) {}
    return Directory.systemTemp;
  }

  Future<File> _flagFile() async {
    final dir = await _storageDir();
    return File('${dir.path}/.borrow_tracker_prompt');
  }

  Future<bool> _hasPromptBeenShown() async {
    try {
      return await _flagFile().then((f) => f.exists());
    } catch (_) {
      return false;
    }
  }

  Future<void> _markPromptShown() async {
    try {
      await (await _flagFile()).create();
    } catch (_) {}
  }

  Future<void> _check() async {
    final shown = await _hasPromptBeenShown();
    if (mounted) {
      setState(() {
        _checking = false;
        _showPrompt = !shown;
      });
    }
  }

  Future<void> _handleNotificationAction(_NotificationAction action) async {
    bool enabled = false;

    if (action == _NotificationAction.enable) {
      try {
        final plugin = FlutterLocalNotificationsPlugin();
        await plugin.initialize(const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ));
        final android = plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (android != null) {
          await android.requestNotificationsPermission();
          await android.requestExactAlarmsPermission();
        }
        enabled = true;
      } catch (e) {
        debugPrint('[FirstRun] Permission error: $e');
      }
    }

    try {
      await _markPromptShown();
      // Also persist via SharedPreferences as a secondary record.
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance().timeout(
          const Duration(seconds: 3),
        );
      } catch (_) {}
      await prefs?.setBool('notification_prompt_shown', true);
      await prefs?.setBool('notification_enabled_from_boot', enabled);
    } catch (e) {
      debugPrint('[FirstRun] Save failed: $e');
    }
    if (mounted) setState(() => _showPrompt = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showPrompt) {
      return _NotificationPrompt(
        onSkip: () => _handleNotificationAction(_NotificationAction.skip),
        onEnable: () => _handleNotificationAction(_NotificationAction.enable),
      );
    }

    return const AuthWrapper();
  }
}

enum _NotificationAction { skip, enable }

/// Full-screen notification prompt that replaces showDialog so it works
/// reliably on devices where Navigator-based dialogs may not appear (MIUI).
class _NotificationPrompt extends StatelessWidget {
  final VoidCallback onSkip;
  final VoidCallback onEnable;

  const _NotificationPrompt({
    required this.onSkip,
    required this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Stay on Track',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Enable notifications to get reminded about upcoming deadlines '
                'and overdue payments.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onEnable,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Enable'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSkip,
                  child: const Text('Skip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Observes app lifecycle and notifies SecurityProvider on resume.
class _AppLifecycleObserver extends StatefulWidget {
  final Widget child;
  const _AppLifecycleObserver({required this.child});

  @override
  State<_AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<_AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<SecurityProvider>();
    if (state == AppLifecycleState.paused) {
      provider.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      provider.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final securityProvider = context.watch<SecurityProvider>();

    // Show loading while checking auth or security state.
    if (authProvider.status == AuthStatus.unknown || securityProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Not authenticated — show login.
    if (authProvider.status == AuthStatus.unauthenticated) {
      return const AuthScreen();
    }

    // Authenticated but app is locked — show biometric prompt.
    if (securityProvider.isLocked) {
      return const _BiometricLockScreen();
    }

    return const DashboardScreen();
  }
}

/// Full-screen lock that prompts for biometric authentication.
class _BiometricLockScreen extends StatefulWidget {
  const _BiometricLockScreen();

  @override
  State<_BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<_BiometricLockScreen> {
  @override
  void initState() {
    super.initState();
    // Prompt immediately on build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    final provider = context.read<SecurityProvider>();
    final success = await provider.unlock();

    if (!success && mounted) {
      // Show retry option after failed attempt.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Authentication failed. Tap lock icon to retry.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'App Locked',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Authenticate to unlock Borrow Tracker',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
