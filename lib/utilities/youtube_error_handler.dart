import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Utility class to handle YouTube player errors gracefully
/// Prevents type mismatch crashes from error codes (int vs String)
class YouTubeErrorHandler {
  /// Create a YouTube controller with error handling wrapper
  static YoutubePlayerController createSafeController({
    required String videoId,
    required BuildContext context,
    bool autoPlay = true,
    bool mute = false,
    VoidCallback? onReady,
    Function(dynamic)? onEnded,
  }) {
    late YoutubePlayerController controller;

    runZonedGuarded(() {
      controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: autoPlay,
          mute: mute,
          enableCaption: false,
          hideControls: false,
          controlsVisibleAtStart: true,
          forceHD: false,
          disableDragSeek: false,
        ),
      );

      // Add error listener with try-catch
      controller.addListener(() {
        try {
          if (controller.value.hasError) {
            _showErrorMessage(
              context,
              controller.value.errorCode,
              videoId,
            );
          }

          // Call custom onReady callback
          if (controller.value.isReady && onReady != null) {
            onReady();
          }
        } catch (e) {
          debugPrint('YouTube player error caught: $e');
          _showGenericError(context);
        }
      });
    }, (error, stack) {
      debugPrint('YouTube player initialization error: $error');
      _showGenericError(context);
    });

    return controller;
  }

  /// Show error message based on error code
  static void _showErrorMessage(
    BuildContext context,
    dynamic errorCode,
    String videoId,
  ) {
    if (!context.mounted) return;

    String message = _getErrorMessage(errorCode);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Show generic error message
  static void _showGenericError(BuildContext context) {
    if (!context.mounted) return;

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

  /// Get user-friendly error message based on error code
  static String _getErrorMessage(dynamic errorCode) {
    // Handle both int and String error codes
    final code = errorCode?.toString() ?? 'unknown';

    switch (code) {
      case '2':
        return 'Invalid video ID. Please try another video.';
      case '5':
        return 'HTML5 player error. Try refreshing the page.';
      case '100':
        return 'Video not found or is private.';
      case '101':
      case '150':
      case '152':
        return 'This video cannot be embedded. The owner has restricted playback.';
      default:
        return 'Video playback error ($code). This video may be unavailable.';
    }
  }

  /// Check if error code indicates embedding is blocked
  static bool isEmbedBlocked(dynamic errorCode) {
    final code = errorCode?.toString() ?? '';
    return code == '101' || code == '150' || code == '152';
  }

  /// Get YouTube app URL for a video
  static String getYouTubeUrl(String videoId) {
    return 'https://www.youtube.com/watch?v=$videoId';
  }
}
