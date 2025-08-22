import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rexplore/model/yt_video.dart';
import 'package:rexplore/model/yt_video_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String firstName = '';
  String lastName = '';
  String email = '';
  String bio = 'This is your bio. Tap edit to update.';
  String avatarUrl = '';

  bool isLoading = true;
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  YtVideo? lastWatched;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc =
          await FirebaseFirestore.instance.collection('count').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          firstName = data['first_name'] ?? '';
          lastName = data['last_name'] ?? '';
          email = data['email'] ?? '';
          bio = data['bio'] ?? 'No bio available.';
          avatarUrl = data['avatar_url'] ?? '';
          // Parse last watched video if saved in Firestore under 'last_watched'
          if (data['last_watched'] != null && data['last_watched'] is Map) {
            final lw = Map<String, dynamic>.from(data['last_watched']);
            lastWatched = YtVideo(
              videoId: lw['videoId'] ?? lw['video_id'] ?? '',
              videoTitle:
                  lw['videoTitle'] ?? lw['video_title'] ?? lw['title'] ?? '',
              thumbnailUrl: lw['thumbnailUrl'] ??
                  lw['thumbnail_url'] ??
                  lw['thumbnail'] ??
                  '',
              viewsCount:
                  lw['viewsCount'] ?? lw['views_count'] ?? lw['views'] ?? '',
              channelName: lw['channelName'] ??
                  lw['channel_name'] ??
                  lw['channel'] ??
                  '',
            );
          } else {
            lastWatched = null;
          }
        });
      } else {
        print("User document not found");
      }
    } catch (e) {
      print('Error loading user info: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  //Updated Supabase upload with cache busting
  Future<void> _uploadAndSaveAvatar(File file) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser!;
      final filePath = "${firebaseUser.uid}/avatar.png";

      final supabase = Supabase.instance.client;

      final response = await supabase.storage
          .from("avatars")
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      if (response == null || response.isEmpty) {
        print("Upload failed: No response from Supabase Storage.");
        return;
      }

      // Get fresh public URL + cache busting with timestamp
      final publicUrl = supabase.storage.from("avatars").getPublicUrl(filePath);
      final cacheBustedUrl =
          "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection("count")
          .doc(firebaseUser.uid)
          .update({"avatar_url": cacheBustedUrl});

      setState(() {
        avatarUrl = cacheBustedUrl;
      });

      print("Upload success! Avatar URL saved with cache busting.");
    } catch (e) {
      print("Supabase upload error: $e");
    }
  }

  void _showEditDialog() {
    nameController.text = "$firstName $lastName";
    bioController.text = bio;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : const AssetImage('lib/icons/ReXplore.png'))
                            as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.camera_alt,
                            size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final fullName = nameController.text.trim();
                  final nameParts = fullName.split(' ');
                  String updatedFirstName =
                      nameParts.isNotEmpty ? nameParts[0] : '';
                  String updatedLastName = nameParts.length > 1
                      ? nameParts.sublist(1).join(' ')
                      : '';

                  setState(() {
                    firstName = updatedFirstName;
                    lastName = updatedLastName;
                    bio = bioController.text.trim();
                  });

                  final uid = FirebaseAuth.instance.currentUser!.uid;

                  //Upload avatar if selected
                  if (_pickedImage != null) {
                    await _uploadAndSaveAvatar(_pickedImage!);
                  }

                  // Update Firestore with new text fields
                  await FirebaseFirestore.instance
                      .collection('count')
                      .doc(uid)
                      .update({
                    'first_name': updatedFirstName,
                    'last_name': updatedLastName,
                    'bio': bio,
                  });

                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                // include viewInsets (keyboard) and bottom system padding to avoid overflow
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).viewInsets.bottom +
                      MediaQuery.of(context).padding.bottom +
                      16,
                ),
                child: Column(
                  children: [
                    // Profile Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            GestureDetector(
                              onTap: _showEditDialog,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage: _pickedImage != null
                                    ? FileImage(_pickedImage!)
                                    : (avatarUrl.isNotEmpty
                                            ? NetworkImage(avatarUrl)
                                            : const AssetImage(
                                                'lib/icons/ReXplore.png'))
                                        as ImageProvider,
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Name & Bio
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "$firstName $lastName",
                                          style: theme.textTheme.headlineSmall!
                                              .copyWith(
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
                                    style: theme.textTheme.bodySmall!
                                        .copyWith(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                      bio,
                                      key: ValueKey(bio),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat("Posts", "12"),
                        _buildStat("Followers", "3.4k"),
                        _buildStat("Following", "120"),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // History
                    _buildSectionTitle("History"),
                    SizedBox(
                      height: 180,
                      child: lastWatched != null
                          ? ListView(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              children: [
                                // show latest watched first
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.86,
                                    child: YoutubeVideoCard(
                                        ytVideo: lastWatched!)),
                                // you can add more history items here if you store them
                              ],
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5,
                              itemBuilder: (context, index) =>
                                  _buildHistoryCard(),
                            ),
                    ),

                    const SizedBox(height: 30),

                    // Your Videos
                    _buildSectionTitle("Your Videos"),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) => _buildVideoCard(),
                    ),
                    // extra spacer so last content isn't flush to the bottom
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 12),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: MediaQuery.of(context).size.width * 0.86,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail area
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(
              child:
                  Icon(Icons.play_circle_fill, size: 40, color: Colors.white70),
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lastWatched?.videoTitle ?? 'Video Title',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastWatched?.channelName ?? 'Channel Name',
                        style: TextStyle(color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lastWatched?.viewsCount ?? '0 views',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(
              child: Icon(Icons.play_arrow, color: Colors.white70, size: 40),
            ),
          ),
          // Title placeholder
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Video Title',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Channel • 0 views',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
