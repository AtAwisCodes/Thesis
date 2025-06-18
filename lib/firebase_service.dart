import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseService();

  Future<bool> addUser({
    required String firstName,
    required String lastName,
    required int age,
    required String email,
    String bio = 'bio',
  }) async {
    try {
      final uid = _auth.currentUser!.uid;

      Map<String, dynamic> userData = {
        'first_name': firstName,
        'last_name': lastName,
        'age': age,
        'email': email,
        'bio': bio,
      };

      await _db.collection('count').doc(uid).set(userData);

      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }
}
