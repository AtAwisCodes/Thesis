import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:rexplore/components/expandable_details.dart';
import 'package:rexplore/image_recognition/cameraFunc.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:rexplore/services/favorites_manager.dart';
import 'package:rexplore/services/video_history_service.dart';

class YtVideoPlayer extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final String viewsCount;
  final String channelName;
  final String thumbnailUrl;

  const YtVideoPlayer({
    super.key,
    required this.videoId,
    required this.videoTitle,
    required this.viewsCount,
    required this.channelName,
    required this.thumbnailUrl,
  });

  @override
  State<YtVideoPlayer> createState() => _YtVideoPlayerState();
}

class _YtVideoPlayerState extends State<YtVideoPlayer> {
  late YoutubePlayerController _controller;
  final List<String> comments = [];
  final VideoHistoryService _historyService = VideoHistoryService();

  bool isFollowed = false;
  bool isLiked = false;
  bool isDisliked = false;
  String _selectedTab = 'Steps'; // Track selected tab: 'Steps' or 'Information'

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    // load initial liked state
    isLiked = FavoritesManager.instance.contains(widget.videoId);

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
  void dispose() {
    // Clear any active snackbars when leaving this page
    ScaffoldMessenger.of(context).clearSnackBars();

    _controller.dispose();
    super.dispose();
  }

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

                      // title
                      Row(
                        children: [
                          Icon(Icons.comment_rounded,
                              color: Theme.of(context).primaryColor),
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
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .iconTheme
                                    .color
                                    ?.withOpacity(0.2),
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                              ),
                              title: Text(
                                "user${index + 1}",
                                style: TextStyle(color: textColor),
                              ),
                              subtitle: Text(
                                comments[index],
                                style: TextStyle(color: textColor),
                              ),
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
                                onPressed: () {
                                  if (_dialogCommentController
                                      .text.isNotEmpty) {
                                    setState(() {
                                      comments.insert(
                                          0, _dialogCommentController.text);
                                    });
                                    setModalState(() {});
                                    _dialogCommentController.clear();
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

  Future<void> _openCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => cameraFunc(camera: cameras[0]),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cameras found')),
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
        _buildInfoRow(Icons.person, 'Channel', widget.channelName),
        const Divider(height: 24),
        _buildInfoRow(Icons.visibility, 'Views', widget.viewsCount),
        const Divider(height: 24),
        _buildInfoRow(Icons.comment, 'Comments', '${comments.length}'),
        const Divider(height: 24),
        _buildInfoRow(
            Icons.thumb_up, 'Status', isLiked ? 'Liked' : 'Not Liked'),
        const Divider(height: 24),
        _buildInfoRow(
          Icons.follow_the_signs,
          'Following',
          isFollowed ? 'Yes' : 'No',
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0, backgroundColor: Colors.transparent, actions: []),
      body: SingleChildScrollView(
        child: YoutubePlayerBuilder(
          player: YoutubePlayer(controller: _controller),
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
                            backgroundImage: CachedNetworkImageProvider(
                              widget.thumbnailUrl,
                            ),
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
                                  FavoritesManager.instance.addFavorite({
                                    'id': widget.videoId,
                                    'title': widget.videoTitle,
                                    'channel': widget.channelName,
                                    'thumbnail': widget.thumbnailUrl,
                                    'views': widget.viewsCount,
                                  });
                                } else {
                                  FavoritesManager.instance
                                      .removeFavorite(widget.videoId);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 2), // closer spacing
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
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 90,
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isFollowed = !isFollowed;
                                });
                              },
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
                  onTap: () => _openComments(context),
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Comments...",
                      style: TextStyle(color: Theme.of(context).hintColor),
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

      // AR Camera button
      floatingActionButton: FloatingActionButton(
        onPressed: _openCamera,
        backgroundColor: Colors.white,
        child: const Icon(Icons.camera_enhance_rounded),
      ),
    );
  }
}
