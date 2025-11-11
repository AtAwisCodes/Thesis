import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const FullscreenVideoPlayer({super.key, required this.controller});

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Lock to landscape when entering fullscreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Listen to video controller changes to update UI
    widget.controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Auto-hide controls after 3 seconds
    _hideControlsAfterDelay();
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${minutes}:${twoDigits(seconds)}';
  }

  @override
  void dispose() {
    // Restore portrait when exiting fullscreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),

            // Play/Pause overlay (center)
            if (_showControls)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      widget.controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 50,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        if (widget.controller.value.isPlaying) {
                          widget.controller.pause();
                        } else {
                          widget.controller.play();
                        }
                      });
                      _hideControlsAfterDelay();
                    },
                  ),
                ),
              ),

            // Bottom controls bar with time indicator and slider (auto-hide)
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Time indicator (current / total)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${_formatDuration(widget.controller.value.position)} / ${_formatDuration(widget.controller.value.duration)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Video progress slider with exit fullscreen button
                      Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                                activeTrackColor: const Color(0xff5BEC84),
                                inactiveTrackColor:
                                    Colors.white.withOpacity(0.3),
                                thumbColor: const Color(0xff5BEC84),
                                overlayColor:
                                    const Color(0xff5BEC84).withOpacity(0.3),
                              ),
                              child: Slider(
                                value: widget
                                    .controller.value.position.inSeconds
                                    .toDouble()
                                    .clamp(
                                      0.0,
                                      widget.controller.value.duration.inSeconds
                                          .toDouble(),
                                    ),
                                min: 0.0,
                                max: widget.controller.value.duration
                                            .inSeconds >
                                        0
                                    ? widget.controller.value.duration.inSeconds
                                        .toDouble()
                                    : 1.0,
                                onChanged: (value) {
                                  widget.controller
                                      .seekTo(Duration(seconds: value.toInt()));
                                  _hideControlsAfterDelay();
                                },
                              ),
                            ),
                          ),
                          // Exit fullscreen button
                          IconButton(
                            icon: const Icon(
                              Icons.fullscreen_exit,
                              color: Colors.white,
                            ),
                            iconSize: 28,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            tooltip: 'Exit Fullscreen',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
