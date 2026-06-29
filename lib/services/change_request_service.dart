import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/change_request.dart';
import '../utils/constants.dart';

class ChangeRequestService {
  final CollectionReference _changeRequestsRef =
      FirebaseFirestore.instance.collection(AppConstants.changeRequestsCollection);

  /// Create a new change request.
  Future<ChangeRequest> createRequest({required ChangeRequest request}) async {
    final docRef = await _changeRequestsRef.add(request.toMap());
    return request.copyWith(id: docRef.id);
  }

  /// Fetch change requests where the user is a participant.
  Stream<List<ChangeRequest>> fetchChangeRequests(String userId) {
    return _changeRequestsRef
        .where('participants', arrayContains: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ChangeRequest.fromMap(data, id: doc.id);
            })
            .toList());
  }

  /// Update the status of a change request (accept/reject/cancel).
  Future<void> updateStatus({
    required String requestId,
    required ChangeRequestStatus status,
  }) async {
    await _changeRequestsRef.doc(requestId).update({
      'status': status.name,
      'resolvedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Delete a change request (used for cleanup after accept/reject).
  Future<void> deleteRequest({required String requestId}) async {
    await _changeRequestsRef.doc(requestId).delete();
  }

  /// Delete all change requests for a given entry (e.g., when the entry is deleted).
  Future<void> deleteRequestsForEntry({required String entryId}) async {
    final snapshot =
        await _changeRequestsRef.where('entryId', isEqualTo: entryId).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
