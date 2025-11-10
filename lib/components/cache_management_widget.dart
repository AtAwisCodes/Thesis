import 'package:flutter/material.dart';
import 'package:rexplore/services/cache_service.dart';

class CacheManagementWidget extends StatefulWidget {
  const CacheManagementWidget({super.key});

  @override
  State<CacheManagementWidget> createState() => _CacheManagementWidgetState();
}

class _CacheManagementWidgetState extends State<CacheManagementWidget> {
  final CacheService _cacheService = CacheService();
  String _cacheSize = 'Calculating...';
  int _fileCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final result = await _cacheService.getCacheSize();
    if (result['success'] && mounted) {
      setState(() {
        _cacheSize = '${result['sizeMB']} MB';
        _fileCount = result['fileCount'];
      });
    }
  }

  Future<void> _clearAllCache() async {
    setState(() => _isLoading = true);

    final result = await _cacheService.clearAllCache();

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result['success'] ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result['success']
                      ? 'Cleared ${result['deletedSizeMB']} MB'
                      : 'Error: ${result['error']}',
                ),
              ),
            ],
          ),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      if (result['success']) {
        await _loadCacheSize();
      }
    }
  }

  Future<void> _clearImageCache() async {
    setState(() => _isLoading = true);

    final result = await _cacheService.clearImageCache();

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['success']
                ? 'Cleared ${result['deletedFiles']} images (${result['deletedSizeMB']} MB)'
                : 'Error: ${result['error']}',
          ),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        await _loadCacheSize();
      }
    }
  }

  Future<void> _clearVideoCache() async {
    setState(() => _isLoading = true);

    final result = await _cacheService.clearVideoCache();

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['success']
                ? 'Cleared ${result['deletedFiles']} videos (${result['deletedSizeMB']} MB)'
                : 'Error: ${result['error']}',
          ),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        await _loadCacheSize();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.cleaning_services,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cache Management',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current cache: $_cacheSize ($_fileCount files)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadCacheSize,
                  tooltip: 'Refresh cache size',
                ),
              ],
            ),
            const Divider(height: 24),

            // Clear All Cache Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _clearAllCache,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.delete_sweep),
                label: const Text('Clear All Cache'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Advanced Options
            ExpansionTile(
              title: const Text('Advanced Options'),
              leading: const Icon(Icons.tune),
              children: [
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Clear Image Cache'),
                  subtitle: const Text('Remove cached images only'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _isLoading ? null : _clearImageCache,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.video_library),
                  title: const Text('Clear Video Cache'),
                  subtitle: const Text('Remove cached videos only'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _isLoading ? null : _clearVideoCache,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Clearing cache frees up storage space. The app will re-download content as needed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
