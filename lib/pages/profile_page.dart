import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rexplore/services/upload_function.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

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
  int postsCount = 0;

  bool isLoading = true;
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  final VideoUploadService _videoService = VideoUploadService();

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
          postsCount = data['posts'] ?? 0; // legacy fetch
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

  Future<void> _uploadAndSaveAvatar(File file) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser!;
      final filePath = "${firebaseUser.uid}/avatar.png";

      final supabase = Supabase.instance.client;

      await supabase.storage
          .from("avatars")
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = supabase.storage.from("avatars").getPublicUrl(filePath);

      await FirebaseFirestore.instance
          .collection("count")
          .doc(firebaseUser.uid)
          .update({"avatar_url": publicUrl});

      setState(() {
        avatarUrl = publicUrl;
      });

      print("Upload success! Avatar URL saved to Firestore.");
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

                  if (_pickedImage != null) {
                    await _uploadAndSaveAvatar(_pickedImage!);
                  }

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

  // Your Videos section
  Widget _buildYourVideosSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _videoService.getUserVideos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Something went wrong while loading your videos."),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("You haven't uploaded any videos yet."),
          );
        }

        final videos = snapshot.data!;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullVideoPlayerPage(video: video),
                  ),
                );
              },
              child: _buildVideoCard(video, key: ValueKey(video['id'])),
            );
          },
        );
      },
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
                padding: const EdgeInsets.all(16),
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

                    // Stats Row (Posts now live count)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _videoService.getUserVideos(),
                          builder: (context, snapshot) {
                            final count =
                                snapshot.hasData ? snapshot.data!.length : 0;
                            return _buildStat("Posts", count.toString());
                          },
                        ),
                        _buildStat("Followers", "3.4k"),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // History
                    _buildSectionTitle("History"),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) => _buildHistoryCard(),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Your Videos
                    _buildSectionTitle("Your Videos"),
                    _buildYourVideosSection(),
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
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
      ),
      child: const Center(child: Text("History Item")),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video, {Key? key}) {
    final String title = video['title'] ?? "Untitled";
    final String url = video['publicUrl'] ?? "";
    final String videoId = video['id'] ?? "";
    final String thumbnailUrl = video['thumbnailUrl'] ?? "";

    Future<void> _deleteVideo() async {
      try {
        // Delete from Firestore
        await FirebaseFirestore.instance
            .collection('videos')
            .doc(videoId)
            .delete();

        // Delete from Supabase storage if exists
        if (url.isNotEmpty) {
          final supabase = Supabase.instance.client;
          final path = Uri.parse(url).pathSegments.skip(1).join('/');
          await supabase.storage.from("videos").remove([path]);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video deleted successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting video: $e")),
        );
      }
    }

    return Container(
      key: key,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black12,
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Thumbnail image
                      thumbnailUrl.isNotEmpty
                          ? Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.black26,
                                  child: const Icon(Icons.broken_image,
                                      size: 40, color: Colors.white54),
                                );
                              },
                            )
                          : Container(
                              color: Colors.black26,
                              child: const Icon(Icons.videocam,
                                  size: 40, color: Colors.white54),
                            ),
                      // Play button overlay
                      const Center(
                        child: Icon(Icons.play_circle_fill,
                            size: 50, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete Video"),
                      content: const Text(
                          "Are you sure you want to delete this video?"),
                      actions: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        TextButton(
                          child: const Text("Delete",
                              style: TextStyle(color: Colors.red)),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _deleteVideo();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Full player page
class FullVideoPlayerPage extends StatelessWidget {
  final Map<String, dynamic> video;
  const FullVideoPlayerPage({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final title = video['title'] ?? "Untitled";
    final description = video['description'] ?? "";
    final url = video['publicUrl'] ?? "";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: url.isNotEmpty
                ? VideoPlayerWidget(videoUrl: url)
                : const Center(child: Icon(Icons.videocam, size: 100)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(description),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller.dispose();
      _initializeController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
