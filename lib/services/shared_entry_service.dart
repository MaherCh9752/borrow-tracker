import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shared_entry_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class SharedEntryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _sharedEntriesRef =>
      _firestore.collection(AppConstants.sharedEntriesCollection);

  CollectionReference get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  /// Creates a new shared entry and returns it with the generated ID.
  Future<SharedEntry> addEntry({required SharedEntry entry}) async {
    final docRef = await _sharedEntriesRef.add(entry.toMap());
    return entry.copyWith(id: docRef.id);
  }

  /// Updates an existing shared entry by document ID.
  Future<void> editEntry({required SharedEntry entry}) async {
    await _sharedEntriesRef.doc(entry.id).update(entry.toMap());
  }

  /// Updates an existing shared entry with a raw map (for applying change requests).
  Future<void> editEntryFromMap({
    required String entryId,
    required Map<String, dynamic> data,
  }) async {
    await _sharedEntriesRef.doc(entryId).update(data);
  }

  /// Deletes a shared entry by document ID.
  Future<void> deleteEntry({required String entryId}) async {
    await _sharedEntriesRef.doc(entryId).delete();
  }

  /// Returns a stream of all shared entries where [userId] is a participant,
  /// ordered by createdAt descending (newest first).
  Stream<List<SharedEntry>> fetchEntries(String userId) {
    return _sharedEntriesRef
        .where('participants', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return SharedEntry.fromMap(data).copyWith(id: doc.id);
            }).toList());
  }

  /// Fetches a single user by UID.
  Future<UserModel?> fetchUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()! as Map<String, dynamic>);
  }

  /// Fetches multiple users by their UIDs.
  Future<List<UserModel>> fetchUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    final futures = uids.map((uid) => fetchUser(uid)).toList();
    final results = await Future.wait(futures);
    return results.whereType<UserModel>().toList();
  }

  /// Fetches all registered users (for the UserPicker).
  Future<List<UserModel>> fetchAllUsers() async {
    final snapshot = await _usersRef.get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
