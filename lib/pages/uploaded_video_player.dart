import 'package:flutter/material.dart';
import 'package:rexplore/components/fullscreen_helper.dart';
import 'package:rexplore/components/expandable_details.dart';
import 'package:video_player/video_player.dart';
import 'package:rexplore/services/favorites_manager.dart';
import 'package:rexplore/augmented_reality/augmented_camera.dart';
import 'package:rexplore/services/upload_function.dart';
import 'package:rexplore/services/follow_service.dart';
import 'package:rexplore/services/notification_service.dart';
import 'package:rexplore/services/video_history_service.dart';
import 'package:rexplore/services/user_profile_sync_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String videoId;
  final String title;
  final String uploadedAt;
  final String avatarUrl;
  final String firstName;
  final String lastName;
  final String thumbnailUrl;

  const UploadedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.videoId,
    required this.title,
    required this.uploadedAt,
    required this.avatarUrl,
    required this.firstName,
    required this.lastName,
    this.thumbnailUrl = '',
  });

  @override
  State<UploadedVideoPlayer> createState() => _UploadedVideoPlayerState();
}

class _UploadedVideoPlayerState extends State<UploadedVideoPlayer> {
  late VideoPlayerController _controller;
  final List<Map<String, dynamic>> comments = [];
  final _commentController = TextEditingController();
  final VideoUploadService _uploadService = VideoUploadService();
  final FollowService _followService = FollowService();
  final NotificationService _notificationService = NotificationService();
  final VideoHistoryService _historyService = VideoHistoryService();
  final UserProfileSyncService _profileSyncService = UserProfileSyncService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isFollowed = false;
  bool isLiked = false;
  bool isDisliked = false;
  int _likeCount = 0;
  bool _isFavorited = false;
  bool _has3DModel = false;
  bool _isCheckingModel = true;
  String? _modelError;
  bool _isLoadingComments = true;
  int _viewCount = 0;
  String? _uploaderUserId;
  bool _showPlayPauseButton = false;
  String _videoDescription = '';
  String _selectedTab = 'Steps'; // Track selected tab: 'Steps' or 'Information'

  @override
  void initState() {
    super.initState();

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('UploadedVideoPlayer initialized');
    print('Video ID: ${widget.videoId}');
    print('Video URL: ${widget.videoUrl}');
    print('Title: ${widget.title}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
        }
      });

    // Load initial liked state
    _isFavorited = FavoritesManager.instance.contains(widget.videoId);

    // Add video to watch history
    _addToHistory();

    // Increment view count when video is opened
    _incrementViewCount();

    // Fetch like count
    _fetchLikeCount();

    // Check 3D model status
    _check3DModelStatus();

    // Load comments
    _loadComments();

    // Load uploader user ID and check follow status
    _loadUploaderInfo();
  }

  /// Load uploader user ID from video document and check follow status
  Future<void> _loadUploaderInfo() async {
    try {
      if (widget.videoId.isEmpty) return;

      final videoDoc =
          await _firestore.collection('videos').doc(widget.videoId).get();
      if (videoDoc.exists) {
        final data = videoDoc.data()!;
        _uploaderUserId = data['userId'] as String?;

        // Load video description if available
        if (data.containsKey('description')) {
          if (mounted) {
            setState(() {
              _videoDescription = data['description'] as String? ?? '';
            });
          }
        }

        if (_uploaderUserId != null) {
          // Check if current user is following this uploader
          final following = await _followService.isFollowing(_uploaderUserId!);
          if (mounted) {
            setState(() {
              isFollowed = following;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading uploader info: $e');
    }
  }

  /// Add video to user's watch history
  Future<void> _addToHistory() async {
    await _historyService.addToHistory(
      videoId: widget.videoId,
      videoUrl: widget.videoUrl,
      title: widget.title,
      thumbnailUrl: widget.thumbnailUrl,
      uploadedAt: widget.uploadedAt,
      avatarUrl: widget.avatarUrl,
      firstName: widget.firstName,
      lastName: widget.lastName,
      videoType: 'uploaded',
    );
  }

  // Increment view count in Firestore
  Future<void> _incrementViewCount() async {
    if (widget.videoId.isEmpty) {
      print('Cannot increment views: Video ID is empty');
      return;
    }

    try {
      print('Incrementing view count for video: ${widget.videoId}');
      await _uploadService.incrementViews(widget.videoId);
      print('View count incremented successfully');

      // Fetch updated view count
      await _fetchViewCount();
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  // Fetch current view count from Firestore
  Future<void> _fetchViewCount() async {
    if (widget.videoId.isEmpty) return;

    try {
      final analytics = await _uploadService.getVideoAnalytics(widget.videoId);
      if (mounted) {
        setState(() {
          _viewCount = analytics['views'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching view count: $e');
    }
  }

  // Fetch current like count from Firestore
  Future<void> _fetchLikeCount() async {
    if (widget.videoId.isEmpty) return;

    try {
      final videoDoc =
          await _firestore.collection('videos').doc(widget.videoId).get();
      if (videoDoc.exists && mounted) {
        final data = videoDoc.data();
        setState(() {
          _likeCount = data?['likeCount'] ?? 0;
        });
      }

      // Check if current user has liked this video
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final likeDoc = await _firestore
            .collection('videos')
            .doc(widget.videoId)
            .collection('likes')
            .doc(currentUser.uid)
            .get();

        if (mounted) {
          setState(() {
            isLiked = likeDoc.exists;
          });
        }
      }
    } catch (e) {
      print('Error fetching like count: $e');
    }
  }

  Future<void> _check3DModelStatus() async {
    try {
      final status = await _uploadService.getModelStatus(widget.videoId);

      if (mounted) {
        setState(() {
          _has3DModel = status['has3DModel'] ?? false;
          _modelError = status['modelGenerationError'];
          _isCheckingModel = false;
        });

        // Show success notification if model is ready
        if (_has3DModel && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('3D Model Ready! Tap "View in AR" to explore'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingModel = false;
        });
      }
    }
  }

  // Load comments from Firestore
  Future<void> _loadComments() async {
    if (widget.videoId.isEmpty) {
      print('Cannot load comments: Video ID is empty');
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
      }
      return;
    }

    try {
      print('Loading comments for video: ${widget.videoId}');
      print('Path: videos/${widget.videoId}/comments');

      final snapshot = await _firestore
          .collection('videos')
          .doc(widget.videoId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();

      print('Found ${snapshot.docs.length} comments');

      if (mounted) {
        setState(() {
          comments.clear();
          for (var doc in snapshot.docs) {
            final data = doc.data();
            print(
                'Comment: ${data['comment']} by ${data['firstName']} ${data['lastName']}');
            comments.add({
              'id': doc.id,
              ...data,
            });
          }
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      print('Error loading comments with ordering: $e');
      try {
        print('Retrying without ordering...');
        final snapshot = await _firestore
            .collection('videos')
            .doc(widget.videoId)
            .collection('comments')
            .get();

        print('Loaded ${snapshot.docs.length} comments without ordering');

        if (mounted) {
          setState(() {
            comments.clear();
            for (var doc in snapshot.docs) {
              comments.add({
                'id': doc.id,
                ...doc.data(),
              });
            }
            _isLoadingComments = false;
          });
        }
      } catch (e2) {
        print('Error loading comments without ordering: $e2');
        if (mounted) {
          setState(() {
            _isLoadingComments = false;
          });
        }
      }
    }
  }

  // Add a new comment to Firestore
  Future<void> _addComment(String commentText) async {
    if (widget.videoId.isEmpty) {
      print('Cannot add comment');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not logged in');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to comment')),
          );
        }
        return;
      }

      print('Adding comment for user: ${user.uid}');
      print('Video ID: ${widget.videoId}');

      // Get user info from Firestore
      final userDoc = await _firestore.collection('count').doc(user.uid).get();

      if (!userDoc.exists) {
        print('User document not found in Firestore');
      }

      final userData = userDoc.data();
      print('User data: $userData');

      final String firstName = userData?['first_name'] ?? 'Anonymous';
      final String lastName = userData?['last_name'] ?? '';
      final String avatarUrl = userData?['avatar_url'] ?? '';

      // Add comment to Firestore
      final commentData = {
        'userId': user.uid,
        'firstName': firstName,
        'lastName': lastName,
        'avatarUrl': avatarUrl,
        'comment': commentText,
        'timestamp': FieldValue.serverTimestamp(),
      };

      print('Saving comment to: videos/${widget.videoId}/comments');
      print('Comment data: $commentData');

      final docRef = await _firestore
          .collection('videos')
          .doc(widget.videoId)
          .collection('comments')
          .add(commentData);

      print('Comment added with ID: ${docRef.id}');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Reload comments to show the new one
      await _loadComments();
    } catch (e) {
      print('Error adding comment: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Delete a comment from Firestore
  Future<void> _deleteComment(String commentId, String commentUserId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not logged in');
        return;
      }

      // Check if the current user owns this comment
      if (user.uid != commentUserId) {
        print('User ${user.uid} cannot delete comment owned by $commentUserId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only delete your own comments'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      print('Deleting comment: $commentId');
      print('Path: videos/${widget.videoId}/comments/$commentId');

      await _firestore
          .collection('videos')
          .doc(widget.videoId)
          .collection('comments')
          .doc(commentId)
          .delete();

      print('Comment deleted successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Reload comments
      await _loadComments();
    } catch (e) {
      print('Error deleting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show delete confirmation dialog
  Future<void> _confirmDeleteComment(
      String commentId, String commentUserId) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != commentUserId) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteComment(commentId, commentUserId);
    }
  }

  @override
  void dispose() {
    // Clear any active snackbars when leaving this page
    ScaffoldMessenger.of(context).clearSnackBars();

    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }

  //Meshy AR Camera with videoId
  Future<void> _openARCamera() async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MeshyARCamera(
            videoId: widget.videoId,
          ),
        ),
      );
    }
  }

  void _enterFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPlayer(controller: _controller),
      ),
    );
  }

  // Toggle like for the video
  Future<void> _toggleLike() async {
    if (widget.videoId.isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to like videos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userId = currentUser.uid;
    final videoRef = _firestore.collection('videos').doc(widget.videoId);
    final likeRef = videoRef.collection('likes').doc(userId);

    try {
      // Use Firestore transaction to ensure accurate like count
      await _firestore.runTransaction((transaction) async {
        final likeDoc = await transaction.get(likeRef);
        final videoDoc = await transaction.get(videoRef);

        final currentLikeCount = videoDoc.data()?['likeCount'] ?? 0;

        if (likeDoc.exists) {
          // User already liked, so unlike
          transaction.delete(likeRef);
          transaction.update(videoRef, {
            'likeCount': currentLikeCount - 1 < 0 ? 0 : currentLikeCount - 1,
          });

          if (mounted) {
            setState(() {
              isLiked = false;
              isDisliked = false;
              _likeCount = currentLikeCount - 1 < 0 ? 0 : currentLikeCount - 1;
            });
          }
        } else {
          // User hasn't liked yet, so add like
          transaction.set(likeRef, {
            'userId': userId,
            'likedAt': FieldValue.serverTimestamp(),
          });
          transaction.update(videoRef, {
            'likeCount': currentLikeCount + 1,
          });

          if (mounted) {
            setState(() {
              isLiked = true;
              isDisliked = false;
              _likeCount = currentLikeCount + 1;
            });
          }

          // Send like notification
          if (_uploaderUserId != null) {
            await _notificationService.sendLikeNotification(
              videoId: widget.videoId,
              videoOwnerId: _uploaderUserId!,
              likerUserId: userId,
              videoTitle: widget.title,
            );
          }
        }
      });
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update like. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      // Revert UI state on error
      await _fetchLikeCount();
    }
  }

  // Toggle favorites
  Future<void> _toggleFavorites() async {
    final videoData = {
      "id": widget.videoId,
      "videoId": widget.videoId,
      "title": widget.title,
      "url": widget.videoUrl,
      "publicUrl": widget.videoUrl,
      "uploadedAt": widget.uploadedAt,
      "thumbnailUrl": widget.thumbnailUrl,
      "avatarUrl": widget.avatarUrl,
      "firstName": widget.firstName,
      "lastName": widget.lastName,
      "views": _viewCount,
    };

    setState(() {
      _isFavorited = !_isFavorited;
    });

    if (_isFavorited) {
      FavoritesManager.instance.addFavorite(videoData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.bookmark, color: Colors.white),
              SizedBox(width: 8),
              Text('Added to favorites'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      FavoritesManager.instance.removeFavorite(widget.videoId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.bookmark_border, color: Colors.white),
              SizedBox(width: 8),
              Text('Removed from favorites'),
            ],
          ),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

// Toggle follow/unfollow for the video uploader
  Future<void> _toggleFollow() async {
    if (_uploaderUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to follow user at this time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to follow users'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Don't allow following yourself
    if (currentUser.uid == _uploaderUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot follow yourself'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isFollowed = !isFollowed;
    });

    bool success;
    if (isFollowed) {
      success = await _followService.followUser(_uploaderUserId!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Now following ${widget.firstName} ${widget.lastName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      success = await _followService.unfollowUser(_uploaderUserId!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unfollowed ${widget.firstName} ${widget.lastName}'),
            backgroundColor: Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    // If operation failed, revert the state
    if (!success) {
      setState(() {
        isFollowed = !isFollowed;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update follow status. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Build video description text with relevant information
  String _buildVideoDescription() {
    // Return only the user-provided description
    return _videoDescription.isNotEmpty ? _videoDescription : '';
  }

  // Open comments modal
  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final TextEditingController _dialogCommentController =
            TextEditingController();

        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return StatefulBuilder(
                builder: (context, setModalState) {
                  final textColor =
                      Theme.of(context).textTheme.bodyMedium?.color;

                  return Column(
                    children: [
                      // drag handle
                      Container(
                        height: 5,
                        width: 40,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: textColor?.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      Row(
                        children: [
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.comment_rounded,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Comments",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // comments list
                      Expanded(
                        child: _isLoadingComments
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 10),
                                    Text('Loading comments...'),
                                  ],
                                ),
                              )
                            : comments.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.comment_outlined,
                                          size: 48,
                                          color: textColor?.withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "No comments yet. Be the first to comment!",
                                          style: TextStyle(
                                            color: textColor?.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    itemCount: comments.length,
                                    itemBuilder: (context, index) {
                                      final comment = comments[index];
                                      final String commentId =
                                          comment['id'] ?? '';
                                      final String commentUserId =
                                          comment['userId'] ?? '';
                                      final String firstName =
                                          comment['firstName'] ?? 'Anonymous';
                                      final String lastName =
                                          comment['lastName'] ?? '';
                                      final String avatarUrl =
                                          comment['avatarUrl'] ?? '';
                                      final String commentText =
                                          comment['comment'] ?? '';
                                      final String displayName =
                                          "$firstName $lastName".trim();

                                      // Check if current user owns this comment
                                      final currentUser = _auth.currentUser;
                                      final isOwnComment =
                                          currentUser != null &&
                                              currentUser.uid == commentUserId;

                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: avatarUrl.isNotEmpty
                                              ? NetworkImage(avatarUrl)
                                              : null,
                                          backgroundColor: avatarUrl.isEmpty
                                              ? Theme.of(context)
                                                  .iconTheme
                                                  .color
                                                  ?.withOpacity(0.2)
                                              : null,
                                          child: avatarUrl.isEmpty
                                              ? Icon(
                                                  Icons.person,
                                                  color: Theme.of(context)
                                                      .iconTheme
                                                      .color,
                                                )
                                              : null,
                                        ),
                                        title: Text(
                                          displayName.isNotEmpty
                                              ? displayName
                                              : "Anonymous",
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          commentText,
                                          style: TextStyle(color: textColor),
                                        ),
                                        trailing: isOwnComment
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  _confirmDeleteComment(
                                                    commentId,
                                                    commentUserId,
                                                  );
                                                },
                                                tooltip: 'Delete comment',
                                              )
                                            : null,
                                      );
                                    },
                                  ),
                      ),

                      // input
                      SafeArea(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            border: Border(
                              top: BorderSide(
                                color: textColor!.withOpacity(0.3),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _dialogCommentController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: "Write a comment...",
                                    hintStyle: TextStyle(
                                        color: textColor.withOpacity(0.6)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: textColor.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.send,
                                    color: Colors.black54),
                                onPressed: () async {
                                  if (_dialogCommentController
                                      .text.isNotEmpty) {
                                    final commentText =
                                        _dialogCommentController.text;
                                    _dialogCommentController.clear();

                                    // Close keyboard
                                    FocusScope.of(context).unfocus();

                                    // Add comment to Firestore
                                    await _addComment(commentText);

                                    // Update modal state
                                    setModalState(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Build the toggle section with Steps and Information tabs
  Widget _buildInfoToggleSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Toggle buttons
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 'Steps';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 'Steps'
                            ? const Color(0xff5BEC84)
                            : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Steps',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _selectedTab == 'Steps'
                                ? Colors.black
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 'Trivia';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 'Trivia'
                            ? const Color(0xff5BEC84)
                            : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Trivia',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _selectedTab == 'Trivia'
                                ? Colors.black
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content area - Scrollable
          Container(
            constraints: const BoxConstraints(
              maxHeight: 300, // Maximum height for scrollable content
              minHeight: 150, // Minimum height
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _selectedTab == 'Steps'
                  ? _buildStepsContent()
                  : _buildInformationContent(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Steps tab content
  Widget _buildStepsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepItem(
          1,
          'Watch the Video',
          'Carefully watch the entire video to understand the content and context.',
        ),
        const SizedBox(height: 12),
        _buildStepItem(
          2,
          'Check for 3D Model',
          'If available, tap "View in AR" to explore the 3D model in augmented reality.',
        ),
        const SizedBox(height: 12),
        _buildStepItem(
          3,
          'Interact and Engage',
          'Like the video, follow the creator, and leave comments to show your support.',
        ),
        const SizedBox(height: 12),
        _buildStepItem(
          4,
          'Share Your Experience',
          'Share this video with friends and help the creator reach more people.',
        ),
        const SizedBox(height: 12),
        _buildStepItem(
          5,
          'Explore More',
          'Check out similar videos and discover new content on ReXplore.',
        ),
      ],
    );
  }

  /// Build a single step item
  Widget _buildStepItem(int stepNumber, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xff5BEC84),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build Information tab content
  Widget _buildInformationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [],
    );
  }

  // Build a single information row
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xff5BEC84),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _uploaderUserId != null
            ? _profileSyncService.getUserProfileStream(_uploaderUserId!)
            : Stream.value(null),
        builder: (context, profileSnapshot) {
          // Use real-time data if available, otherwise use widget data
          final firstName =
              profileSnapshot.hasData && profileSnapshot.data != null
                  ? (profileSnapshot.data!['first_name'] ?? widget.firstName)
                  : widget.firstName;
          final lastName =
              profileSnapshot.hasData && profileSnapshot.data != null
                  ? (profileSnapshot.data!['last_name'] ?? widget.lastName)
                  : widget.lastName;
          final avatarUrl =
              profileSnapshot.hasData && profileSnapshot.data != null
                  ? (profileSnapshot.data!['avatar_url'] ?? widget.avatarUrl)
                  : widget.avatarUrl;

          final uploaderName = "$firstName $lastName".trim();

          return SingleChildScrollView(
            child: Column(
              children: [
                // Video Player with fixed container
                Container(
                  height: 250,
                  width: double.infinity,
                  color: Colors.black,
                  child: _controller.value.isInitialized
                      ? Stack(
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
                                  : Center(
                                      child: AspectRatio(
                                        aspectRatio:
                                            _controller.value.aspectRatio,
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
                                      _controller.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            // Fullscreen button
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: IconButton(
                                icon: const Icon(Icons.fullscreen,
                                    color: Colors.white),
                                onPressed: _enterFullscreen,
                              ),
                            ),
                          ],
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ),
                // Expandable Details Section
                ExpandableDetails(
                  title: widget.title,
                  details: _buildVideoDescription(),
                  viewCount: _viewCount,
                  uploadedAt: widget.uploadedAt,
                  maxLinesCollapsed: 2,
                  actionButton: Container(
                    decoration: BoxDecoration(
                      color: _isFavorited
                          ? const Color(0xff5BEC84).withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isFavorited ? Icons.bookmark : Icons.bookmark_border,
                        color: _isFavorited
                            ? const Color(0xff5BEC84)
                            : Colors.grey[600],
                      ),
                      onPressed: _toggleFavorites,
                      tooltip: _isFavorited
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                    ),
                  ),
                ),

                // Uploader Avatar + Name + Actions
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Uploader info with real-time data
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            uploaderName.isNotEmpty
                                ? uploaderName
                                : "Anonymous",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      // Like / Dislike / Follow
                      Row(
                        children: [
                          // Like button with count
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.thumb_up,
                                  color: isLiked ? Colors.green : Colors.grey,
                                ),
                                onPressed: _toggleLike,
                              ),
                              Text(
                                '$_likeCount',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          // Dislike button
                          IconButton(
                            icon: Icon(
                              Icons.thumb_down,
                              color: isDisliked ? Colors.red : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                isDisliked = !isDisliked;
                                if (isDisliked) isLiked = false;
                              });
                            },
                          ),
                          const SizedBox(width: 10),
                          // Follow button
                          SizedBox(
                            width: 90,
                            height: 36,
                            child: ElevatedButton(
                              onPressed: _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowed
                                    ? Colors.grey
                                    : const Color(0xff5BEC84),
                                padding: EdgeInsets.zero,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  isFollowed ? "Followed" : "Follow",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isFollowed
                                        ? Colors.white70
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // comments trigger
                GestureDetector(
                  onTap: () {
                    if (widget.videoId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Comments cannot be loaded.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                    _openComments(context);
                  },
                  child: Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width * 0.97,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            widget.videoId.isEmpty ? Colors.red : Colors.grey,
                        width: widget.videoId.isEmpty ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (widget.videoId.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(Icons.warning,
                                    color: Colors.red, size: 20),
                              ),
                            Text(
                              widget.videoId.isEmpty
                                  ? "Comments (missing something)"
                                  : "Comments...",
                              style: TextStyle(
                                color: widget.videoId.isEmpty
                                    ? Colors.red
                                    : Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                        if (comments.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${comments.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Like Toggle Button with Steps and Information
                _buildInfoToggleSection(),
              ],
            ),
          );
        },
      ),

      // Updated Floating Action Button with Model Status
      floatingActionButton: _buildARButton(),
    );
  }

  Widget _buildARButton() {
    if (_isCheckingModel) {
      return FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: Colors.grey,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        label: const Text(
          "Checking...",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (_has3DModel) {
      return FloatingActionButton.extended(
        onPressed: _openARCamera,
        backgroundColor: const Color(0xff5BEC84),
        icon: const Icon(Icons.view_in_ar, color: Colors.black),
        label: const Text(
          "View in AR",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
    }

    if (_modelError != null) {
      return FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('3D Model Error: $_modelError'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Implement retry logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Retry feature coming soon!'),
                    ),
                  );
                },
              ),
            ),
          );
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        label: const Text(
          "Model Failed",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No 3D model available for this video'),
            backgroundColor: Colors.orange,
          ),
        );
      },
      backgroundColor: Colors.orange,
      icon: const Icon(Icons.block, color: Colors.white),
      label: const Text(
        "No Model",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
