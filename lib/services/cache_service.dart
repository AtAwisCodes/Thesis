import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Clear all app cache including images, videos, and temporary files
  Future<Map<String, dynamic>> clearAllCache() async {
    try {
      int deletedFiles = 0;
      int deletedSize = 0;

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final tempFiles = tempDir.listSync(recursive: true);
        for (var file in tempFiles) {
          if (file is File) {
            try {
              deletedSize += await file.length();
              await file.delete();
              deletedFiles++;
            } catch (e) {
              print('Error deleting temp file: $e');
            }
          }
        }
      }

      // Get cache directory
      final cacheDir = await getApplicationCacheDirectory();
      if (await cacheDir.exists()) {
        final cacheFiles = cacheDir.listSync(recursive: true);
        for (var file in cacheFiles) {
          if (file is File) {
            try {
              deletedSize += await file.length();
              await file.delete();
              deletedFiles++;
            } catch (e) {
              print('Error deleting cache file: $e');
            }
          }
        }
      }

      // Clear Firestore cache
      try {
        await _firestore.clearPersistence();
        print('✅ Firestore cache cleared');
      } catch (e) {
        print('⚠️ Firestore cache clear warning: $e');
        // This is expected if there are active listeners
      }

      final sizeMB = (deletedSize / (1024 * 1024)).toStringAsFixed(2);
      print('✅ Cache cleared: $deletedFiles files, $sizeMB MB');

      return {
        'success': true,
        'deletedFiles': deletedFiles,
        'deletedSize': deletedSize,
        'deletedSizeMB': sizeMB,
      };
    } catch (e) {
      print('❌ Error clearing cache: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Clear only image cache
  Future<Map<String, dynamic>> clearImageCache() async {
    try {
      int deletedFiles = 0;
      int deletedSize = 0;

      final cacheDir = await getApplicationCacheDirectory();
      if (await cacheDir.exists()) {
        final imageExtensions = [
          '.jpg',
          '.jpeg',
          '.png',
          '.gif',
          '.webp',
          '.bmp'
        ];
        final cacheFiles = cacheDir.listSync(recursive: true);

        for (var file in cacheFiles) {
          if (file is File) {
            final ext =
                file.path.toLowerCase().substring(file.path.lastIndexOf('.'));
            if (imageExtensions.contains(ext)) {
              try {
                deletedSize += await file.length();
                await file.delete();
                deletedFiles++;
              } catch (e) {
                print('Error deleting image: $e');
              }
            }
          }
        }
      }

      final sizeMB = (deletedSize / (1024 * 1024)).toStringAsFixed(2);
      print('✅ Image cache cleared: $deletedFiles files, $sizeMB MB');

      return {
        'success': true,
        'deletedFiles': deletedFiles,
        'deletedSize': deletedSize,
        'deletedSizeMB': sizeMB,
      };
    } catch (e) {
      print('❌ Error clearing image cache: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Clear only video cache
  Future<Map<String, dynamic>> clearVideoCache() async {
    try {
      int deletedFiles = 0;
      int deletedSize = 0;

      final cacheDir = await getApplicationCacheDirectory();
      if (await cacheDir.exists()) {
        final videoExtensions = [
          '.mp4',
          '.mov',
          '.avi',
          '.mkv',
          '.webm',
          '.3gp'
        ];
        final cacheFiles = cacheDir.listSync(recursive: true);

        for (var file in cacheFiles) {
          if (file is File) {
            final ext =
                file.path.toLowerCase().substring(file.path.lastIndexOf('.'));
            if (videoExtensions.contains(ext)) {
              try {
                deletedSize += await file.length();
                await file.delete();
                deletedFiles++;
              } catch (e) {
                print('Error deleting video: $e');
              }
            }
          }
        }
      }

      final sizeMB = (deletedSize / (1024 * 1024)).toStringAsFixed(2);
      print('✅ Video cache cleared: $deletedFiles files, $sizeMB MB');

      return {
        'success': true,
        'deletedFiles': deletedFiles,
        'deletedSize': deletedSize,
        'deletedSizeMB': sizeMB,
      };
    } catch (e) {
      print('❌ Error clearing video cache: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get current cache size
  Future<Map<String, dynamic>> getCacheSize() async {
    try {
      int totalSize = 0;
      int fileCount = 0;

      // Check temp directory
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final tempFiles = tempDir.listSync(recursive: true);
        for (var file in tempFiles) {
          if (file is File) {
            try {
              totalSize += await file.length();
              fileCount++;
            } catch (e) {
              // Skip files we can't read
            }
          }
        }
      }

      // Check cache directory
      final cacheDir = await getApplicationCacheDirectory();
      if (await cacheDir.exists()) {
        final cacheFiles = cacheDir.listSync(recursive: true);
        for (var file in cacheFiles) {
          if (file is File) {
            try {
              totalSize += await file.length();
              fileCount++;
            } catch (e) {
              // Skip files we can't read
            }
          }
        }
      }

      final sizeMB = (totalSize / (1024 * 1024)).toStringAsFixed(2);
      final sizeKB = (totalSize / 1024).toStringAsFixed(2);

      return {
        'success': true,
        'totalSize': totalSize,
        'sizeMB': sizeMB,
        'sizeKB': sizeKB,
        'fileCount': fileCount,
      };
    } catch (e) {
      print('❌ Error getting cache size: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Clear cache and show result in a dialog
  static Future<void> clearCacheWithDialog(BuildContext context) async {
    final cacheService = CacheService();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Clearing cache...'),
          ],
        ),
      ),
    );

    // Clear cache
    final result = await cacheService.clearAllCache();

    // Close loading dialog
    if (context.mounted) {
      Navigator.pop(context);

      // Show result dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                result['success'] ? Icons.check_circle : Icons.error,
                color: result['success'] ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 10),
              Text(result['success'] ? 'Cache Cleared' : 'Error'),
            ],
          ),
          content: Text(
            result['success']
                ? 'Successfully cleared ${result['deletedFiles']} files\n'
                    'Freed up ${result['deletedSizeMB']} MB'
                : 'Error: ${result['error']}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
