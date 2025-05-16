import 'package:flutter/material.dart';
import 'dart:io'; // For File (if using image picker)

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = 'Louis Libusada';
  String email = 'libusadal@gmail.com';
  String bio = 'This is your bio. Tap edit to update.';
  String avatarPath = 'lib/icons/ReXplore.png'; // Local asset path

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  void _showEditDialog() {
    nameController.text = userName;
    bioController.text = bio;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(avatarPath),
              ),
              const SizedBox(height: 10),

              // Name input
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),

              // Bio input
              TextField(
                controller: bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                userName = nameController.text;
                bio = bioController.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Profile section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + Bio in a column
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage(avatarPath),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 100,
                        child: Text(
                          bio,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // Name, Email, Edit
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: _showEditDialog,
                            ),
                          ],
                        ),
                        Text(
                          email,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // History section
              Row(
                children: const [
                  Text(
                    "History",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(),
                ),
              ),

              const SizedBox(height: 10),

              // Videos section
              Row(
                children: const [
                  Text(
                    "Your Videos",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
