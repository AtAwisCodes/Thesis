import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rexplore/pages/landing_page.dart';
import 'package:rexplore/pages/home_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in AND email is verified, check account status
        if (authSnapshot.hasData && authSnapshot.data!.emailVerified) {
          // Listen to user document in real-time to check for suspension/deletion
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(authSnapshot.data!.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // If user document exists, check status
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final isDeleted = userData['isDeleted'] ?? false;
                final isSuspended = userData['isSuspended'] ?? false;

                // If account is deleted, sign out and show error
                if (isDeleted) {
                  Future.microtask(() async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Your account has been deleted by administrators. Please contact support if you believe this is an error.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  });
                  return const LandingPage();
                }

                // If account is suspended, check if suspension has expired
                if (isSuspended) {
                  final suspensionEndDate =
                      userData['suspensionEndDate'] as Timestamp?;

                  if (suspensionEndDate != null) {
                    final endDate = suspensionEndDate.toDate();

                    // If suspension expired, auto-unsuspend
                    if (DateTime.now().isAfter(endDate)) {
                      Future.microtask(() async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(authSnapshot.data!.uid)
                            .update({'isSuspended': false});
                      });
                      // Allow access
                      return const HomePage();
                    }
                  }

                  // Still suspended - sign out and show error
                  final reason = userData['suspensionReason'] ??
                      'Community guideline violations';
                  final daysLeft = suspensionEndDate != null
                      ? suspensionEndDate
                              .toDate()
                              .difference(DateTime.now())
                              .inDays +
                          1
                      : 'indefinite';

                  Future.microtask(() async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Your account is suspended. Reason: $reason. Duration: $daysLeft days remaining.'),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  });
                  return const LandingPage();
                }

                // Account is active and verified, allow access
                return const HomePage();
              }

              // User document doesn't exist - create it for legacy users and allow access
              // This handles users who registered before the 'users' collection was implemented
              Future.microtask(() async {
                try {
                  final countDoc = await FirebaseFirestore.instance
                      .collection('count')
                      .doc(authSnapshot.data!.uid)
                      .get();

                  if (countDoc.exists) {
                    final countData = countDoc.data()!;
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(authSnapshot.data!.uid)
                        .set({
                      'displayName':
                          '${countData['first_name'] ?? ''} ${countData['last_name'] ?? ''}'
                              .trim(),
                      'email':
                          countData['email'] ?? authSnapshot.data!.email ?? '',
                      'avatarUrl': countData['avatar_url'] ?? '',
                      'createdAt': countData['created_at'] ??
                          FieldValue.serverTimestamp(),
                      'isSuspended': false,
                      'isDeleted': false,
                    });
                  }
                } catch (e) {
                  print('Error creating user document for legacy user: $e');
                }
              });

              return const HomePage();
            },
          );
        }
        return const LandingPage();
      },
    );
  }
}
