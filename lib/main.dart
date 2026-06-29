import 'package:flutter/material.dart';
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
  await Firebase.initializeApp();

  // Enable Firestore offline persistence (default on mobile, explicit for clarity).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  try {
    await Workmanager().initialize(notificationCallbackDispatcher);
  } catch (e) {
    debugPrint('[Main] WorkManager init failed: $e');
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

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('notification_prompt_shown') ?? false;
    if (mounted) {
      if (!shown) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPrompt();
        });
      }
      setState(() => _checking = false);
    }
  }

  Future<void> _showPrompt() async {
    final action = await showDialog<_NotificationAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Stay on Track'),
        content: const Text(
          'Enable notifications to get reminded about upcoming deadlines '
          'and overdue payments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _NotificationAction.skip),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, _NotificationAction.enable),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    final prefs = await SharedPreferences.getInstance();
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

    await prefs.setBool('notification_prompt_shown', true);
    await prefs.setBool('notification_enabled_from_boot', enabled);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const AuthWrapper();
  }
}

enum _NotificationAction { skip, enable }

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
