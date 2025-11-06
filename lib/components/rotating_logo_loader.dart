import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom rotating loading animation with ReXplore logo
///
/// This widget displays a rotating logo animation that can be used
/// as a loading indicator throughout the app.
///
/// Features:
/// - Smooth continuous rotation
/// - Customizable size
/// - Optional text below the loader
/// - Uses app's primary green color
/// - Can use custom image or default circular design
class RotatingLogoLoader extends StatefulWidget {
  /// Size of the loader (width and height)
  final double size;

  /// Optional text to display below the loader
  final String? text;

  /// Optional custom image path (if null, uses default design)
  final String? imagePath;

  /// Duration for one complete rotation
  final Duration rotationDuration;

  /// Color of the loader (defaults to primary green)
  final Color? color;

  const RotatingLogoLoader({
    super.key,
    this.size = 60.0,
    this.text,
    this.imagePath,
    this.rotationDuration = const Duration(seconds: 2),
    this.color,
  });

  @override
  State<RotatingLogoLoader> createState() => _RotatingLogoLoaderState();
}

class _RotatingLogoLoaderState extends State<RotatingLogoLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.rotationDuration,
      vsync: this,
    )..repeat(); // Continuous rotation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loaderColor = widget.color ?? const Color(0xff5BEC84);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rotating loader
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2.0 * math.pi,
              child: child,
            );
          },
          child: widget.imagePath != null
              ? _buildImageLoader(loaderColor)
              : _buildDefaultLoader(loaderColor),
        ),

        // Optional text
        if (widget.text != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.text!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Build loader with custom image
  Widget _buildImageLoader(Color color) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          widget.imagePath!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Build default circular loader with green design
  Widget _buildDefaultLoader(Color color) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
            ),
          ),

          // Inner circle with cutout
          Container(
            width: widget.size * 0.7,
            height: widget.size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
          ),

          // Center dot
          Container(
            width: widget.size * 0.25,
            height: widget.size * 0.25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),

          // Accent arc
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _ArcPainter(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the accent arc
class _ArcPainter extends CustomPainter {
  final Color color;

  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.15,
      size.width * 0.7,
      size.height * 0.7,
    );

    // Draw arc from 0 to 120 degrees
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from top
      math.pi * 0.66, // 120 degrees
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact version - smaller loader without text
class CompactRotatingLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const CompactRotatingLoader({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RotatingLogoLoader(
      size: size,
      color: color,
    );
  }
}

/// Full-screen loader with overlay
class FullScreenLoader extends StatelessWidget {
  final String? message;
  final double? progress; // 0.0 to 1.0, null for indeterminate

  const FullScreenLoader({
    super.key,
    this.message,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotatingLogoLoader(
                size: 80,
                text: message ?? 'Loading...',
              ),

              // Progress bar if progress is specified
              if (progress != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xff5BEC84),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress! * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline loader - for use in buttons or small spaces
class InlineLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const InlineLoader({
    super.key,
    this.size = 20.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: RotatingLogoLoader(
        size: size,
        color: color ?? Colors.white,
      ),
    );
  }
}
