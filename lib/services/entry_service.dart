import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/borrow_lend.dart';
import '../utils/constants.dart';

class EntryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _entriesRef(String userId) => _firestore
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .collection(AppConstants.entriesSubCollection);

  /// Creates a new borrow/lend entry and returns it with the generated ID.
  Future<BorrowLend> addEntry({
    required String userId,
    required BorrowLend entry,
  }) async {
    final docRef = await _entriesRef(userId).add(entry.toMap());
    return entry.copyWith(id: docRef.id);
  }

  /// Updates an existing entry by document ID.
  Future<void> editEntry({
    required String userId,
    required BorrowLend entry,
  }) async {
    await _entriesRef(userId).doc(entry.id).update(entry.toMap());
  }

  /// Deletes an entry by document ID.
  Future<void> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    await _entriesRef(userId).doc(entryId).delete();
  }

  /// Returns a stream of all entries for the given user, newest first.
  Stream<List<BorrowLend>> fetchEntries(String userId) {
    return _entriesRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return BorrowLend.fromMap(data).copyWith(id: doc.id);
            }).toList());
  }
}
