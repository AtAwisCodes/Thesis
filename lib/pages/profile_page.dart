import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rexplore/services/upload_function.dart';
import 'package:rexplore/services/follow_service.dart';
import 'package:rexplore/services/video_history_service.dart';
import 'package:rexplore/services/user_profile_sync_service.dart';
import 'package:rexplore/pages/uploaded_video_player.dart';
import 'package:rexplore/pages/yt_video_player.dart';
import 'package:rexplore/components/recycle_gif_loader.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';

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
  int followersCount = 0;
  int followingCount = 0;

  bool isLoading = true;
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  final VideoUploadService _videoService = VideoUploadService();
  final FollowService _followService = FollowService();
  final VideoHistoryService _historyService = VideoHistoryService();
  final UserProfileSyncService _profileSyncService = UserProfileSyncService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No user logged in');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final uid = currentUser.uid;
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
          postsCount = data['posts'] ?? 0;
          followersCount = data['followersCount'] ?? 0;
          followingCount = data['followingCount'] ?? 0;
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
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        print("No user logged in");
        return;
      }

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
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'Name',
                  counterStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ),
              TextField(
                controller: bioController,
                maxLength: 500,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  counterStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    Navigator.pop(context);
                    return;
                  }

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

                  final uid = currentUser.uid;
                  String updatedAvatarUrl = avatarUrl;

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: RecycleGifLoader(
                        size: 80,
                        text: 'Saving profile...',
                      ),
                    ),
                  );

                  try {
                    // Upload avatar if changed
                    if (_pickedImage != null) {
                      await _uploadAndSaveAvatar(_pickedImage!);
                      updatedAvatarUrl = avatarUrl; // Get updated avatar URL
                    }

                    // Update Firestore user profile
                    await FirebaseFirestore.instance
                        .collection('count')
                        .doc(uid)
                        .update({
                      'first_name': updatedFirstName,
                      'last_name': updatedLastName,
                      'bio': bio,
                    });

                    // Sync profile changes to all videos, comments, etc.
                    await _profileSyncService.syncAllUserData(
                      userId: uid,
                      firstName: updatedFirstName,
                      lastName: updatedLastName,
                      avatarUrl: updatedAvatarUrl,
                    );

                    // Close loading dialog
                    if (mounted) Navigator.pop(context);

                    // Close edit dialog
                    if (mounted) Navigator.pop(context);

                    // Show success message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    // Close loading dialog
                    if (mounted) Navigator.pop(context);

                    print('Error updating profile: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating profile: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show followers list
  void _showFollowersList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final uid = currentUser.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                height: 5,
                width: 40,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Followers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _followService.getFollowers(uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: RecycleGifLoader(
                          size: 60,
                          text: 'Loading followers...',
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No followers yet'),
                      );
                    }

                    final followers = snapshot.data!;
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: followers.length,
                      itemBuilder: (context, index) {
                        final follower = followers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: follower['avatarUrl'] != null &&
                                    follower['avatarUrl'].isNotEmpty
                                ? NetworkImage(follower['avatarUrl'])
                                : null,
                            child: follower['avatarUrl'] == null ||
                                    follower['avatarUrl'].isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            '${follower['firstName']} ${follower['lastName']}',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Show following list
  void _showFollowingList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final uid = currentUser.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                height: 5,
                width: 40,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Following',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _followService.getFollowing(uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: RecycleGifLoader(
                          size: 60,
                          text: 'Loading following...',
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('Not following anyone yet'),
                      );
                    }

                    final following = snapshot.data!;
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: following.length,
                      itemBuilder: (context, index) {
                        final user = following[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user['avatarUrl'] != null &&
                                    user['avatarUrl'].isNotEmpty
                                ? NetworkImage(user['avatarUrl'])
                                : null,
                            child: user['avatarUrl'] == null ||
                                    user['avatarUrl'].isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            '${user['firstName']} ${user['lastName']}',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
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
          return SizedBox(
            height: 220,
            child: Center(
              child: RecycleGifLoader(
                size: 70,
                text: 'Loading your videos...',
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: Text(
                "You haven't uploaded any videos yet.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final videos = snapshot.data!;
        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
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
          ),
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
            ? Center(
                child: RecycleGifLoader(
                  size: 80,
                  text: 'Loading profile...',
                ),
              )
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

                    // Stats Row
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
                        GestureDetector(
                          onTap: _showFollowersList,
                          child: _buildStat(
                              "Followers", followersCount.toString()),
                        ),
                        GestureDetector(
                          onTap: _showFollowingList,
                          child: _buildStat(
                              "Following", followingCount.toString()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // History
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle("History"),
                        TextButton.icon(
                          onPressed: _clearAllHistory,
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          label: const Text('Clear All'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    _buildHistorySection(),

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

  /// Show confirmation dialog and clear all history
  Future<void> _clearAllHistory() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to clear your entire watch history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      await _historyService.clearHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Watch history cleared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // History section with functional video playback
  Widget _buildHistorySection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _historyService.getHistory(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Error loading history"),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: Text(
                "No watch history yet",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final historyVideos = snapshot.data!;
        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: historyVideos.length,
            itemBuilder: (context, index) {
              final video = historyVideos[index];
              return _buildHistoryVideoCard(video);
            },
          ),
        );
      },
    );
  }

  // Build individual history video card
  Widget _buildHistoryVideoCard(Map<String, dynamic> video) {
    final String title = video['title'] ?? "Untitled";
    final String thumbnailUrl = video['thumbnailUrl'] ?? "";
    final String videoType = video['videoType'] ?? 'uploaded';
    final String videoId = video['videoId'] ?? "";

    return GestureDetector(
      onTap: () {
        if (videoType == 'youtube') {
          _playYouTubeVideo(video);
        } else {
          _playUploadedVideo(video);
        }
      },
      onLongPress: () async {
        // Show delete confirmation on long press
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove from History'),
            content: Text('Remove "$title" from your watch history?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
        );

        if (shouldDelete == true && videoId.isNotEmpty) {
          await _historyService.removeFromHistory(videoId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Removed from history'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
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
                                        size: 30, color: Colors.white54),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.black26,
                                child: const Icon(Icons.videocam,
                                    size: 30, color: Colors.white54),
                              ),
                        // Play button overlay
                        const Center(
                          child: Icon(Icons.play_circle_fill,
                              size: 40, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            // Delete button overlay
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove from History'),
                      content: Text('Remove "$title" from your watch history?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete == true && videoId.isNotEmpty) {
                    await _historyService.removeFromHistory(videoId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Removed from history'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Play YouTube video from history
  void _playYouTubeVideo(Map<String, dynamic> video) {
    final String videoId = video['videoId'] ?? '';
    final String title = video['title'] ?? 'Untitled';
    final String thumbnailUrl = video['thumbnailUrl'] ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YtVideoPlayer(
          videoId: videoId,
          videoTitle: title,
          viewsCount: '0',
          channelName: '',
          thumbnailUrl: thumbnailUrl,
        ),
      ),
    );
  }

  // Play uploaded video from history
  void _playUploadedVideo(Map<String, dynamic> video) async {
    final String videoId = video['videoId'] ?? '';
    final String videoUrl = video['videoUrl'] ?? '';
    final String title = video['title'] ?? 'Untitled';
    final String thumbnailUrl = video['thumbnailUrl'] ?? '';

    if (videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video URL is missing")),
      );
      return;
    }

    // Format uploaded date
    String uploadedAtText = video['uploadedAt'] ?? 'Unknown date';
    if (video['uploadedAt'] is Timestamp) {
      final date = (video['uploadedAt'] as Timestamp).toDate();
      uploadedAtText = DateFormat('MMM d, yyyy').format(date);
    }

    // Navigate to video player with AR support
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadedVideoPlayer(
          videoUrl: videoUrl,
          title: title,
          uploadedAt: uploadedAtText,
          avatarUrl: video['avatarUrl'] ?? '',
          firstName: video['firstName'] ?? '',
          lastName: video['lastName'] ?? '',
          videoId: videoId,
          thumbnailUrl: thumbnailUrl,
        ),
      ),
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
          const SnackBar(
            content: Text("Video deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting video: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return Container(
      key: key,
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with fixed height
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: Colors.black12,
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
                      // Dark gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
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
              // Title section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Delete button overlay
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
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
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete, color: Colors.white, size: 18),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video player with fixed container
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.black,
              child: url.isNotEmpty
                  ? VideoPlayerWidget(videoUrl: url)
                  : const Center(
                      child: Icon(Icons.videocam,
                          size: 100, color: Colors.white54),
                    ),
            ),
            // Title and description
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
  bool _showPlayPauseButton = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
        }
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
  void deactivate() {
    // Pause video when navigating away or widget is deactivated
    if (_controller.value.isInitialized) {
      _controller.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
              _showPlayPauseButton = true;
            });

            // Hide the button after 1 second
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  _showPlayPauseButton = false;
                });
              }
            });
          },
          child: _controller.value.aspectRatio > 1
              ? // Landscape video - fill the space
              SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                )
              : // Portrait video - center with aspect ratio
              Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
        ),
        // Play/Pause button overlay
        if (_showPlayPauseButton)
          Center(
            child: AnimatedOpacity(
              opacity: _showPlayPauseButton ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
