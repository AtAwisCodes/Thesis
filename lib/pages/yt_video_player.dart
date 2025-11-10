import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rexplore/components/expandable_details.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:rexplore/services/favorites_manager.dart';
import 'package:rexplore/services/video_history_service.dart';
import 'package:url_launcher/url_launcher.dart';

class YtVideoPlayer extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final String viewsCount;
  final String channelName;
  final String thumbnailUrl;
  final String? channelAvatarUrl;

  const YtVideoPlayer({
    super.key,
    required this.videoId,
    required this.videoTitle,
    required this.viewsCount,
    required this.channelName,
    required this.thumbnailUrl,
    this.channelAvatarUrl,
  });

  @override
  State<YtVideoPlayer> createState() => _YtVideoPlayerState();
}

class _YtVideoPlayerState extends State<YtVideoPlayer> {
  late YoutubePlayerController _controller;
  final VideoHistoryService _historyService = VideoHistoryService();

  bool isLiked = false;
  bool isDisliked = false;
  bool _isFavorited = false;
  int _likeCount = 0;
  String _selectedTab = 'Steps';

  @override
  void initState() {
    super.initState();

    // Wrap controller initialization in error zone to catch type errors
    runZonedGuarded(() {
      _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: false,
          hideControls: false,
          controlsVisibleAtStart: true,
          forceHD: false,
          disableDragSeek: false,
        ),
      )..addListener(() {
          // Handle player errors
          try {
            if (_controller.value.hasError) {
              final errorCode = _controller.value.errorCode.toString();
              print(
                  'YouTube Player Error: Code $errorCode for video ${widget.videoId}');

              if (mounted) {
                String errorMessage = 'Video playback error';
                bool canOpenInYouTube = false;

                // Detailed error messages based on error code
                switch (errorCode) {
                  case '2':
                    errorMessage = 'Invalid video ID';
                    break;
                  case '5':
                    errorMessage = 'HTML5 player error';
                    break;
                  case '100':
                    errorMessage = 'Video not found or is private';
                    break;
                  case '101':
                  case '150':
                  case '152':
                    errorMessage =
                        'This video cannot be embedded. The owner has restricted playback outside YouTube.';
                    canOpenInYouTube = true;
                    break;
                  default:
                    errorMessage =
                        'Video playback error (Code: $errorCode). This video may be restricted or unavailable.';
                    canOpenInYouTube = true;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    duration: const Duration(seconds: 6),
                    backgroundColor: Colors.red,
                    action: canOpenInYouTube
                        ? SnackBarAction(
                            label: 'Open in YouTube',
                            textColor: Colors.white,
                            onPressed: () => _openYouTubeVideo(),
                          )
                        : SnackBarAction(
                            label: 'Dismiss',
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                  ),
                );
              }
            }
          } catch (e) {
            // Catch the type error from error code handling
            print('Error in player listener: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'This video cannot be played. It may be restricted or region-locked.',
                  ),
                  duration: Duration(seconds: 5),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        });
    }, (error, stack) {
      // Catch any errors from the YouTube player initialization
      print('YouTube player error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to load video. Please try again or choose another video.',
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // load initial liked state
    _isFavorited = FavoritesManager.instance.contains(widget.videoId);
    isLiked = _isFavorited;

    // Initialize like count based on favorited state
    _likeCount = _isFavorited ? 1 : 0;

    // Add to video history
    _addToHistory();
  }

  /// Add YouTube video to user's watch history
  Future<void> _addToHistory() async {
    await _historyService.addToHistory(
      videoId: widget.videoId,
      videoUrl: 'https://www.youtube.com/watch?v=${widget.videoId}',
      title: widget.videoTitle,
      thumbnailUrl: widget.thumbnailUrl,
      videoType: 'youtube',
    );
  }

  @override
  void deactivate() {
    // Pause YouTube video when navigating away
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    // Clear any active snackbars when leaving this page
    ScaffoldMessenger.of(context).clearSnackBars();

    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    // Show message that YouTube videos don't have AR models
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'AR features are only available for user-uploaded videos. YouTube videos do not have 3D models.',
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Open YouTube video page in browser
  Future<void> _openYouTubeVideo() async {
    final url = Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open YouTube'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening YouTube: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Open YouTube channel page in browser
  Future<void> _openYouTubeChannel() async {
    // Search for the channel on YouTube
    final searchUrl = Uri.parse(
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(widget.channelName)}');
    try {
      if (await canLaunchUrl(searchUrl)) {
        await launchUrl(searchUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open YouTube'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening YouTube: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Build video description text with relevant information
  String _buildVideoDescription() {
    final description = StringBuffer();

    description.write("Channel: ${widget.channelName}\n");
    description.write("\nWatch this amazing video on ReXplore! ");
    description.write("Like, follow, and share to support the creator.");

    return description.toString();
  }

  /// Toggle video favorite status
  void _toggleFavorites() {
    setState(() {
      _isFavorited = !_isFavorited;
      if (_isFavorited) {
        FavoritesManager.instance.addFavorite({
          'id': widget.videoId,
          'title': widget.videoTitle,
          'channel': widget.channelName,
          'thumbnail': widget.thumbnailUrl,
          'views': widget.viewsCount,
          'videoType': 'youtube',
          'channelAvatarUrl': widget.channelAvatarUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.bookmark, color: Colors.white),
                SizedBox(width: 8),
                Text('Added to favorites'),
              ],
            ),
            backgroundColor: Color(0xff5BEC84),
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
    });
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
                            ? Theme.of(context).primaryColor
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
                                ? Theme.of(context).scaffoldBackgroundColor
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
                            ? Theme.of(context).primaryColor
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
                                ? Theme.of(context).scaffoldBackgroundColor
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

          // Content area - Scrollable and responsive
          LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = MediaQuery.of(context).size.height;
              // Make max height responsive: 40% of screen height but not less than 300 or more than 600
              final responsiveMaxHeight =
                  (screenHeight * 0.4).clamp(300.0, 600.0);

              return Container(
                constraints: BoxConstraints(
                  maxHeight: responsiveMaxHeight,
                  minHeight: 150,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 24, // Extra bottom padding to prevent cutoff
                  ),
                  child: _selectedTab == 'Steps'
                      ? _buildStepsContent()
                      : _buildInformationContent(),
                ),
              );
            },
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
          'Carefully watch the YouTube video to understand the content and context.',
        ),
        const SizedBox(height: 12),
        _buildStepItem(
          2,
          'Use AR Camera',
          'Tap the camera button to explore augmented reality features and scan objects.',
        ),
        const SizedBox(height: 12),
        _buildStepItem(
          3,
          'Interact and Engage',
          'Like the video, follow the channel, and leave comments to show your support.',
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

  /// Build Information tab content
  Widget _buildInformationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.video_library, 'Video ID', widget.videoId),
        const Divider(height: 24),
        _buildInfoRow(Icons.title, 'Title', widget.videoTitle),
        const Divider(height: 24),
        _buildChannelInfoRow(),
        const Divider(height: 24),
        _buildInfoRow(Icons.visibility, 'Views', widget.viewsCount),
        const Divider(height: 24),
        _buildInfoRow(
            Icons.thumb_up, 'Status', isLiked ? 'Liked' : 'Not Liked'),
        const Divider(height: 24),
        const Text(
          'About:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This is a YouTube video shared on ReXplore. Watch, like, and engage with the content. Use the AR camera feature to explore augmented reality experiences.',
          style: TextStyle(
            fontSize: 14,
            color:
                Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// Build a single information row
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

  /// Build channel information row with avatar
  Widget _buildChannelInfoRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Channel avatar or icon
        widget.channelAvatarUrl != null && widget.channelAvatarUrl!.isNotEmpty
            ? CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(widget.channelAvatarUrl!),
                backgroundColor: Colors.grey[300],
              )
            : CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xff5BEC84).withOpacity(0.2),
                child: const Icon(
                  Icons.person,
                  size: 20,
                  color: Color(0xff5BEC84),
                ),
              ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Channel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.channelName,
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
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.red,
            progressColors: const ProgressBarColors(
              playedColor: Colors.red,
              handleColor: Colors.redAccent,
            ),
            onReady: () {
              print('YouTube player is ready');
            },
            onEnded: (metadata) {
              print('Video ended');
            },
          ),
          builder: (context, player) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                player,

                // title
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      widget.videoTitle,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                // Expandable Details Section
                ExpandableDetails(
                  title: widget.videoTitle,
                  details: _buildVideoDescription(),
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

                // Channel thumbnail + actions
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: widget.thumbnailUrl.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    widget.thumbnailUrl,
                                  )
                                : null,
                            child: widget.thumbnailUrl.isEmpty
                                ? const Icon(Icons.person, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.channelName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
                                onPressed: () {
                                  setState(() {
                                    isLiked = !isLiked;
                                    if (isLiked) {
                                      isDisliked = false;
                                      _likeCount++;
                                    } else {
                                      _likeCount =
                                          _likeCount > 0 ? _likeCount - 1 : 0;
                                    }
                                  });
                                },
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
                                if (isDisliked) {
                                  isLiked = false;
                                  _likeCount =
                                      _likeCount > 0 ? _likeCount - 1 : 0;
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 90,
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () async {
                                await _openYouTubeChannel();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff5BEC84),
                                padding: EdgeInsets.zero,
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Follow",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
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

                // comments trigger - opens YouTube video
                GestureDetector(
                  onTap: () async {
                    // Show dialog explaining the redirect
                    final shouldOpen = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.comment, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Comment on YouTube'),
                          ],
                        ),
                        content: const Text(
                          'You\'ll be redirected to YouTube to view and post comments for this video.',
                          style: TextStyle(fontSize: 16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Open YouTube'),
                          ),
                        ],
                      ),
                    );

                    if (shouldOpen == true) {
                      await _openYouTubeVideo();
                    }
                  },
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Comment on YouTube...",
                            style:
                                TextStyle(color: Theme.of(context).hintColor),
                          ),
                        ),
                        const Icon(Icons.open_in_new,
                            size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Like Toggle Button with Steps and Information
                _buildInfoToggleSection(),

                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),

      // AR Button - YouTube videos don't have AR models
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCamera,
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.block, color: Colors.white),
        label: const Text(
          "No Model",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
