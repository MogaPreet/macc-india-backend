import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic Firestore service for CRUD operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new document to a collection
  Future<String> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = await _firestore.collection(collection).add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add document: $e');
    }
  }

  /// Update an existing document
  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  /// Delete a document
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  /// Get a single document
  Future<DocumentSnapshot> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  /// Get all documents in a collection
  Future<QuerySnapshot> getCollection({
    required String collection,
    Query Function(Query)? queryBuilder,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      return await query.get();
    } catch (e) {
      throw Exception('Failed to get collection: $e');
    }
  }

  /// Stream collection for real-time updates
  Stream<QuerySnapshot> streamCollection({
    required String collection,
    Query Function(Query)? queryBuilder,
  }) {
    try {
      Query query = _firestore.collection(collection);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      return query.snapshots();
    } catch (e) {
      throw Exception('Failed to stream collection: $e');
    }
  }

  /// Set document (create or overwrite)
  Future<void> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(docId)
          .set(data, SetOptions(merge: merge));
    } catch (e) {
      throw Exception('Failed to set document: $e');
    }
  }

  /// Batch write operations
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();

      for (final op in operations) {
        final type = op['type'] as String;
        final collection = op['collection'] as String;
        final docId = op['docId'] as String?;
        final data = op['data'] as Map<String, dynamic>?;

        final docRef = docId != null
            ? _firestore.collection(collection).doc(docId)
            : _firestore.collection(collection).doc();

        switch (type) {
          case 'set':
            batch.set(docRef, data!);
            break;
          case 'update':
            batch.update(docRef, data!);
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to execute batch write: $e');
    }
  }
}
