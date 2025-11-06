import 'package:flutter/material.dart';

/// Recycle GIF Loading Animation
///
/// A beautiful, eye-friendly loading indicator using the recycle GIF animation.
/// Features optimal sizing for various contexts.
class RecycleGifLoader extends StatelessWidget {
  /// Size of the loader (width and height)
  final double size;

  /// Optional text to display below the loader
  final String? text;

  /// Text style for the optional text
  final TextStyle? textStyle;

  const RecycleGifLoader({
    super.key,
    this.size = 80.0, // Optimal default size - easy on the eyes
    this.text,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // GIF Loader with smooth rendering
        SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            'lib/icons/Recycle.gif',
            width: size,
            height: size,
            fit: BoxFit.contain,
            // Add anti-aliasing for smooth rendering
            filterQuality: FilterQuality.high,
            // Prevent jagged edges
            isAntiAlias: true,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if GIF is not found
              return Icon(
                Icons.recycling,
                size: size * 0.7,
                color: const Color(0xff5BEC84),
              );
            },
          ),
        ),

        // Optional text below loader
        if (text != null) ...[
          const SizedBox(height: 16),
          Text(
            text!,
            style: textStyle ??
                TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Compact variant for buttons and small spaces
class CompactRecycleLoader extends StatelessWidget {
  final double size;

  const CompactRecycleLoader({
    super.key,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'lib/icons/Recycle.gif',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.recycling,
            size: size * 0.7,
            color: const Color(0xff5BEC84),
          );
        },
      ),
    );
  }
}

/// Inline variant for buttons
class InlineRecycleLoader extends StatelessWidget {
  final double size;
  final String? label;

  const InlineRecycleLoader({
    super.key,
    this.size = 20.0,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            'lib/icons/Recycle.gif',
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.recycling,
                size: size * 0.7,
                color: const Color(0xff5BEC84),
              );
            },
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 8),
          Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Full-screen overlay loader with optional progress
class FullScreenRecycleLoader extends StatelessWidget {
  final String? message;
  final double? progress; // 0.0 to 1.0

  const FullScreenRecycleLoader({
    super.key,
    this.message,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Large GIF loader
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset(
                    'lib/icons/Recycle.gif',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.recycling,
                        size: 70,
                        color: const Color(0xff5BEC84),
                      );
                    },
                  ),
                ),

                if (message != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    message!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Optional progress bar
                if (progress != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xff5BEC84),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(progress! * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Recommended Sizes Guide:
/// 
/// - **Extra Small (16-20px)**: Inline text, tiny indicators
/// - **Small (24-32px)**: Buttons, compact cards, list items
/// - **Medium (50-60px)**: Standard cards, small dialogs
/// - **Default (80px)**: ✨ **RECOMMENDED** - Most pages, centered loading
/// - **Large (100-120px)**: Full-page loading, modals, important states
/// - **Extra Large (140px+)**: Splash screens, hero sections
/// 
/// The default 80px size is carefully chosen to be:
/// ✓ Easy on the eyes
/// ✓ Clearly visible
/// ✓ Not too small or overwhelming
/// ✓ Works on all screen sizes
/// ✓ Professional appearance
