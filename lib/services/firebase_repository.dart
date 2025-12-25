import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/version_model.dart';

class FirebaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches version data from the "versions" collection
  /// Default document ID is "current"
  Future<VersionModel?> getVersion({String documentId = 'current'}) async {
    try {
      log('Fetching version document with ID: $documentId');
      
      final DocumentSnapshot doc = await _firestore
          .collection('versions')
          .doc(documentId)
          .get();

      if (!doc.exists) {
        log('Version document $documentId does not exist');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      log('Version document data: $data');

      final model = VersionModel.fromJson(data);
      log('Parsed version model - Android: ${model.androidVersion}, iOS: ${model.iosVersion}, Released: ${model.isReleased}');

      return model;
    } catch (e, stackTrace) {
      log('Error fetching version: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Check if Firestore is accessible (for testing)
  Future<bool> checkConnection() async {
    try {
      await _firestore.collection('versions').limit(1).get();
      return true;
    } catch (e) {
      log('Firestore connection check failed: $e');
      return false;
    }
  }
}

