import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Google Sign in
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Sign out first to ensure account picker is shown
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      //begin interactive sign in process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // User cancelled the sign-in
      if (googleUser == null) {
        return null;
      }

      //obtain with details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      //create a new credential for user
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      //finally, lets sign in
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Check if this is a new user and create Firestore document
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(userCredential.user!);
      } else {
        // For existing users, check if account is deleted
        await checkAccountStatus(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign out from both Firebase and Google
  Future<void> signOut() async {
    try {
      // Sign out from Google (disconnect to force account selection next time)
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.disconnect();
      await googleSignIn.signOut();

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      print('Successfully signed out from both Google and Firebase');
    } catch (e) {
      print('Error signing out: $e');
      // Even if disconnect fails, still try to sign out
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
      } catch (e2) {
        print('Error in fallback sign out: $e2');
      }
      rethrow;
    }
  }

  /// Check if user account is deleted or suspended
  Future<void> checkAccountStatus(User user) async {
    try {
      // Check in 'users' collection first (admin management)
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final isDeleted = userData['isDeleted'] ?? false;
        final isSuspended = userData['isSuspended'] ?? false;

        if (isDeleted) {
          // Sign out immediately
          await FirebaseAuth.instance.signOut();
          throw Exception(
              'This account has been ban by administrators. Please contact support if you believe this is an error.');
        }

        if (isSuspended) {
          // Check if suspension has expired
          final suspensionEndDate = userData['suspensionEndDate'] as Timestamp?;

          if (suspensionEndDate != null) {
            final endDate = suspensionEndDate.toDate();
            if (DateTime.now().isAfter(endDate)) {
              // Auto-unsuspend if suspension period has ended
              await _firestore.collection('users').doc(user.uid).update({
                'isSuspended': false,
              });
              // Allow access to continue
              return;
            }
          }

          // Still suspended - sign out
          await FirebaseAuth.instance.signOut();
          final reason =
              userData['suspensionReason'] ?? 'Community guideline violations';
          final daysLeft = suspensionEndDate != null
              ? suspensionEndDate.toDate().difference(DateTime.now()).inDays + 1
              : 'indefinite';
          throw Exception(
              'Your account has been suspended. Reason: $reason. Duration: $daysLeft days remaining.');
        }
      }
    } catch (e) {
      print('Error checking account status: $e');
      rethrow;
    }
  }

  /// Create user document in Firestore for Google sign-in users
  Future<void> _createUserDocument(User user) async {
    try {
      // Extract first and last name from display name
      String firstName = '';
      String lastName = '';
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        final nameParts = user.displayName!.split(' ');
        firstName = nameParts.first;
        if (nameParts.length > 1) {
          lastName = nameParts.sublist(1).join(' ');
        }
      }

      Map<String, dynamic> userData = {
        'first_name': firstName,
        'last_name': lastName,
        'age': 0, // Default age, user can update later
        'email': user.email ?? '',
        'bio': 'bio',
        'avatar_url': user.photoURL ?? '',
        'created_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('count').doc(user.uid).set(userData);

      // Also create initial user document in 'users' collection for admin management
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'avatarUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'isSuspended': false,
        'isDeleted': false,
      });
    } catch (e) {
      print('Error creating user document: $e');
      rethrow;
    }
  }
}
