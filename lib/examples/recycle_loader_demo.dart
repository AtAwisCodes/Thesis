import 'package:flutter/material.dart';
import '../components/recycle_gif_loader.dart';

/// Demo page showing all recycle GIF loader variants
class RecycleLoaderDemo extends StatefulWidget {
  const RecycleLoaderDemo({super.key});

  @override
  State<RecycleLoaderDemo> createState() => _RecycleLoaderDemoState();
}

class _RecycleLoaderDemoState extends State<RecycleLoaderDemo> {
  double _progress = 0.0;
  bool _showFullScreen = false;

  @override
  void initState() {
    super.initState();
    // Simulate progress
    Future.delayed(const Duration(milliseconds: 100), _updateProgress);
  }

  void _updateProgress() {
    if (mounted) {
      setState(() {
        _progress = (_progress + 0.01) % 1.0;
      });
      Future.delayed(const Duration(milliseconds: 50), _updateProgress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle GIF Loader Demo'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                'Default Size (80px)',
                'Optimal for most use cases - easy on the eyes',
                const RecycleGifLoader(
                  text: 'Loading...',
                ),
              ),

              _buildSection(
                'Large Size (120px)',
                'For full-page loading or important states',
                const RecycleGifLoader(
                  size: 120,
                  text: 'Processing...',
                ),
              ),

              _buildSection(
                'Medium Size (60px)',
                'For cards and dialogs',
                const RecycleGifLoader(
                  size: 60,
                  text: 'Please wait',
                ),
              ),

              _buildSection(
                'Small Size (40px)',
                'For compact spaces',
                const RecycleGifLoader(
                  size: 40,
                ),
              ),

              _buildSection(
                'Compact Loader (24px)',
                'For list items and small indicators',
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CompactRecycleLoader(),
                    SizedBox(width: 12),
                    Text('Loading profile...'),
                  ],
                ),
              ),

              _buildSection(
                'Inline Loader (20px)',
                'For buttons and inline text',
                const Center(
                  child: InlineRecycleLoader(
                    label: 'Uploading',
                  ),
                ),
              ),

              _buildSection(
                'Button Integration',
                'How it looks in buttons',
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: null,
                      child: const InlineRecycleLoader(
                        label: 'Processing',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: null,
                      child: const InlineRecycleLoader(
                        label: 'Loading',
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),

              _buildSection(
                'Card with Loader',
                'Loader in a card component',
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const RecycleGifLoader(
                          size: 70,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Analyzing waste type...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              _buildSection(
                'Full-Screen Loader',
                'Tap button to see overlay loader',
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _showFullScreen = true);
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted) {
                        setState(() => _showFullScreen = false);
                      }
                    });
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Show Full-Screen Loader'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Size comparison
              _buildSection(
                'Size Comparison',
                'All sizes side by side',
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    _sizeBox('16px', 16),
                    _sizeBox('24px', 24),
                    _sizeBox('40px', 40),
                    _sizeBox('60px', 60),
                    _sizeBox('80px\n(Default)', 80),
                    _sizeBox('100px', 100),
                    _sizeBox('120px', 120),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),

          // Full-screen overlay
          if (_showFullScreen)
            FullScreenRecycleLoader(
              message: 'Uploading video...',
              progress: _progress,
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
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
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(child: child),
          ),
        ],
      ),
    );
  }

  Widget _sizeBox(String label, double size) {
    return Column(
      children: [
        RecycleGifLoader(size: size),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
