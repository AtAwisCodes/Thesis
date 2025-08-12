import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Create or update user account
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
        'created_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('count').doc(uid).set(userData);
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  /// Upload video to Firebase Storage and get download URL
  Future<String> uploadVideo(String filePath) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final file = File(filePath);
      final fileName = '${DateTime.now()}.mp4';
      final ref = _storage.ref().child('videos/${user.uid}/$fileName');

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading video: $e');
      rethrow;
    }
  }

  /// Save video metadata under the user's document
  Future<void> saveVideoToUser(String videoUrl,
      {String videoName = 'User Video'}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore
          .collection('count')
          .doc(user.uid)
          .collection('videos')
          .add({
        'url': videoUrl,
        'name': videoName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving video metadata: $e');
    }
  }
}
