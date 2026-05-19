import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'providers/auth_provider.dart';
import 'providers/entry_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/notification_callback.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Workmanager().initialize(notificationCallbackDispatcher);
  runApp(const BorrowTrackerApp());
}

class BorrowTrackerApp extends StatelessWidget {
  const BorrowTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EntryProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const FirstRunGate(),
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    switch (authProvider.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return const DashboardScreen();
      case AuthStatus.unauthenticated:
        return const AuthScreen();
    }
  }
}
