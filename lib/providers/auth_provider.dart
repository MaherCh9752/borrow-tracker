import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pending_invite_model.dart';
import '../services/auth_service.dart';
import '../services/invite_service.dart';
import '../models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  Timer? _fallbackTimer;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    // Check synchronous cached state first — avoids waiting for the stream.
    final cachedUser = _authService.currentUser;
    if (cachedUser != null) {
      _status = AuthStatus.authenticated;
      _user = UserModel.fromFirebaseUser(
        cachedUser.uid,
        cachedUser.email ?? '',
        cachedUser.displayName,
      );
    }

    // Listen for auth state changes.
    _authService.authStateChanges.listen(_onAuthStateChanged);

    // Fallback: if the stream never fires (e.g. platform channel hangs on
    // certain MIUI devices), force unauthenticated after a few seconds.
    _fallbackTimer = Timer(const Duration(seconds: 8), () {
      if (_status == AuthStatus.unknown) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
        debugPrint('[Auth] Fallback timer fired — forcing unauthenticated');
      }
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _fallbackTimer?.cancel();
    if (firebaseUser != null) {
      _status = AuthStatus.authenticated;
      _user ??= UserModel.fromFirebaseUser(
        firebaseUser.uid,
        firebaseUser.email ?? '',
        firebaseUser.displayName,
      );
    } else {
      _status = AuthStatus.unauthenticated;
      _user = null;
    }
    notifyListeners();
  }

  /// Sign in with email and password.
  Future<bool> signIn(String email, String password) async {
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Register a new user.
  Future<bool> signUp(
    String email,
    String password,
    String displayName, {
    PendingInvite? invite,
  }) async {
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _status = AuthStatus.authenticated;

      if (invite != null && _user != null) {
        try {
          final inviteService = InviteService();
          await inviteService.processInviteAfterSignup(
            invite: invite,
            newUserId: _user!.uid,
            newUserDisplayName: displayName,
          );
        } catch (e) {
          debugPrint('[Auth] Failed to process invite after signup: $e');
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Send password reset email.
  Future<bool> resetPassword(String email) async {
    _error = null;
    notifyListeners();
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Clear displayed error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}