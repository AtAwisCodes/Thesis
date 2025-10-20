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
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No user logged in');
        return false;
      }

      final uid = currentUser.uid;

      Map<String, dynamic> userData = {
        'first_name': firstName,
        'last_name': lastName,
        'age': age,
        'email': email,
        'bio': bio,
        'avatar_url': '',
        'created_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('count').doc(uid).set(userData);
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }
}
