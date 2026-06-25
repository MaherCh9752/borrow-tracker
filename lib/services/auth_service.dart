import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the current authenticated user, or null.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // Create user doc if missing (legacy migration)
        final userModel = UserModel.fromFirebaseUser(
          user.uid,
          user.email ?? email,
          user.displayName,
        );
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(userModel.toMap());
        return userModel;
      }

      return UserModel.fromMap(doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  /// Register a new user with email and password.
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;

      await user.updateDisplayName(displayName);

      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  /// Fetches all registered users (for the UserPicker).
  Future<List<UserModel>> fetchAllUsers() async {
    final snapshot =
        await _firestore.collection(AppConstants.usersCollection).get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
  }

  /// Searches users by displayName or email (case-insensitive contains).
  /// Returns up to [limit] results.
  Future<List<UserModel>> searchUsers(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    final snapshot =
        await _firestore.collection(AppConstants.usersCollection).get();
    final results = <UserModel>[];
    for (final doc in snapshot.docs) {
      final user = UserModel.fromMap(doc.data());
      final name = (user.displayName ?? '').toLowerCase();
      final email = user.email.toLowerCase();
      if (name.contains(q) || email.contains(q)) {
        results.add(user);
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  /// Fetches a single user by UID.
  Future<UserModel?> fetchUserById(String uid) async {
    final doc =
        await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Maps FirebaseAuthException to a user-friendly message.
  Exception _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email.');
      case 'wrong-password':
        return Exception('Incorrect password.');
      case 'email-already-in-use':
        return Exception('This email is already registered.');
      case 'invalid-email':
        return Exception('Invalid email address.');
      case 'weak-password':
        return Exception('Password should be at least 6 characters.');
      case 'invalid-credential':
        return Exception('Invalid email or password.');
      default:
        return Exception('An error occurred: ${e.message}');
    }
  }
}