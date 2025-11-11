import 'package:flutter/material.dart';
import 'package:rexplore/components/error_notification.dart';

/// Example demonstrating how to use the ErrorNotification component
/// to display modern, user-friendly error messages.
class ErrorNotificationExample extends StatelessWidget {
  const ErrorNotificationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Notification Examples'),
        backgroundColor: const Color(0xff2A303E),
      ),
      backgroundColor: const Color(0xff1E2330),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Login Error Example
              ElevatedButton(
                onPressed: () {
                  ErrorNotification.show(
                    context,
                    "Invalid email or password",
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Login Error',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Empty Field Example
              ElevatedButton(
                onPressed: () {
                  ErrorNotification.show(
                    context,
                    "Please enter your email address",
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Empty Field Error',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Disposable Email Example
              ElevatedButton(
                onPressed: () {
                  ErrorNotification.show(
                    context,
                    "Disposable email addresses are not allowed.\nPlease use a permanent email address.",
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Disposable Email Error',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Network Error Example
              ElevatedButton(
                onPressed: () {
                  ErrorNotification.show(
                    context,
                    "Unable to sign in with Google. Please try again.",
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Google Sign-in Error',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
