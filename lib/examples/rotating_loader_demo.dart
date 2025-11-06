import 'package:flutter/material.dart';
import 'package:rexplore/components/rotating_logo_loader.dart';

/// Demo page showing all rotating loader variants
///
/// This page demonstrates all available loader types and
/// their usage in different scenarios.
class RotatingLoaderDemoPage extends StatefulWidget {
  const RotatingLoaderDemoPage({super.key});

  @override
  State<RotatingLoaderDemoPage> createState() => _RotatingLoaderDemoPageState();
}

class _RotatingLoaderDemoPageState extends State<RotatingLoaderDemoPage> {
  bool _isLoading = false;
  bool _showFullScreen = false;
  double _progress = 0.0;

  void _simulateProgress() {
    setState(() {
      _progress = 0.0;
      _showFullScreen = true;
    });

    // Simulate progress
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _updateProgress();
      }
    });
  }

  void _updateProgress() {
    if (_progress < 1.0) {
      setState(() {
        _progress += 0.05;
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _updateProgress();
        }
      });
    } else {
      setState(() {
        _showFullScreen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotating Loader Demo'),
      ),
      body: Stack(
        children: [
          _buildDemoContent(),
          if (_showFullScreen)
            FullScreenLoader(
              message: 'Uploading...',
              progress: _progress,
            ),
        ],
      ),
    );
  }

  Widget _buildDemoContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Rotating Loading Animations',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Beautiful, consistent loaders for ReXplore',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          // Default Loader
          _buildSection(
            title: '1. Default Rotating Logo Loader',
            description: 'Main loading state with optional text',
            child: const Center(
              child: RotatingLogoLoader(
                size: 60,
                text: 'Loading content...',
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Size Variants
          _buildSection(
            title: '2. Size Variants',
            description: 'Different sizes for different contexts',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Column(
                  children: [
                    RotatingLogoLoader(size: 40),
                    SizedBox(height: 8),
                    Text('Small', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    RotatingLogoLoader(size: 60),
                    SizedBox(height: 8),
                    Text('Medium', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    RotatingLogoLoader(size: 80),
                    SizedBox(height: 8),
                    Text('Large', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Compact Loader
          _buildSection(
            title: '3. Compact Rotating Loader',
            description: 'For small spaces and inline use',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                CompactRotatingLoader(size: 16),
                CompactRotatingLoader(size: 24),
                CompactRotatingLoader(size: 32),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Inline Loader in Button
          _buildSection(
            title: '4. Inline Loader (In Buttons)',
            description: 'Perfect for button loading states',
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() => _isLoading = !_isLoading);
                    if (_isLoading) {
                      Future.delayed(const Duration(seconds: 3), () {
                        if (mounted) setState(() => _isLoading = false);
                      });
                    }
                  },
                  child: _isLoading
                      ? const InlineLoader(size: 20, color: Colors.black)
                      : const Text('Upload Video'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      InlineLoader(
                        size: 16,
                        color: Color(0xff5BEC84),
                      ),
                      SizedBox(width: 8),
                      Text('Processing...'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Color Variants
          _buildSection(
            title: '5. Color Variants',
            description: 'Customize colors to match context',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                RotatingLogoLoader(
                  size: 50,
                  color: Color(0xff5BEC84),
                ),
                RotatingLogoLoader(
                  size: 50,
                  color: Colors.blue,
                ),
                RotatingLogoLoader(
                  size: 50,
                  color: Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Full Screen Demo
          _buildSection(
            title: '6. Full-Screen Loader with Progress',
            description: 'For blocking operations with progress tracking',
            child: ElevatedButton.icon(
              onPressed: _simulateProgress,
              icon: const Icon(Icons.upload),
              label: const Text('Simulate Upload'),
            ),
          ),

          const SizedBox(height: 32),

          // List Example
          _buildSection(
            title: '7. In List Items',
            description: 'Loading states for list content',
            child: Column(
              children: [
                _buildListItem('User 1', true),
                _buildListItem('User 2', false),
                _buildListItem('User 3', true),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Card Example
          _buildSection(
            title: '8. In Cards',
            description: 'Loading states for card content',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    RotatingLogoLoader(
                      size: 50,
                      text: 'Loading video details...',
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Custom Image Example
          _buildSection(
            title: '9. With Custom Image',
            description: 'Use your own logo or image',
            child: const Center(
              child: RotatingLogoLoader(
                size: 80,
                imagePath: 'lib/icons/ReXplore.png',
                text: 'ReXplore',
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildListItem(String name, bool isLoading) {
    return ListTile(
      leading: isLoading
          ? const CompactRotatingLoader(size: 40)
          : CircleAvatar(
              backgroundColor: const Color(0xff5BEC84),
              child: Text(
                name[0],
                style: const TextStyle(color: Colors.white),
              ),
            ),
      title: Text(name),
      subtitle: isLoading
          ? const Text('Loading...')
          : const Text('Active • 2 min ago'),
      trailing: isLoading
          ? const CompactRotatingLoader(size: 20)
          : const Icon(Icons.chevron_right),
    );
  }
}
