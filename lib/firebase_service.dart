import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create or update user account in Firestore
  Future<bool> addUser({
    required String firstName,
    required String lastName,
    required int age,
    required String email,
    String bio = 'bio',
    String? uid, // Optional UID parameter
  }) async {
    try {
      // Use provided UID or get current user's UID
      final userId = uid ?? _auth.currentUser?.uid;

      if (userId == null) {
        print('No user ID available');
        return false;
      }

      Map<String, dynamic> userData = {
        'first_name': firstName,
        'last_name': lastName,
        'age': age,
        'email': email,
        'bio': bio,
        'avatar_url': '',
        'created_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('count').doc(userId).set(userData);

      // Also create initial user document in 'users' collection for admin management
      await _firestore.collection('users').doc(userId).set({
        'displayName': '$firstName $lastName',
        'email': email,
        'avatarUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'isSuspended': false,
        'isDeleted': false,
      });

      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }
}
