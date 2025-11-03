/// INTEGRATION EXAMPLES FOR DISPOSAL GUIDE SYSTEM
///
/// This file shows how to integrate the disposal category system into:
/// 1. Video Upload Page
/// 2. Video Player Page (Trivia Section)
/// 3. Firestore Database

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rexplore/data/disposal_guides/disposal_categories.dart';
import 'package:rexplore/data/disposal_guides/disposal_info_data.dart';
import 'package:rexplore/components/category_selector_widget.dart';
import 'package:rexplore/components/disposal_trivia_widget.dart';

// =============================================================================
// EXAMPLE 1: Add to Video Upload Page
// =============================================================================

class VideoUploadPageExample extends StatefulWidget {
  const VideoUploadPageExample({super.key});

  @override
  State<VideoUploadPageExample> createState() => _VideoUploadPageExampleState();
}

class _VideoUploadPageExampleState extends State<VideoUploadPageExample> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DisposalCategory? _selectedCategory;
  String? _videoUrl;

  Future<void> _uploadVideo() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      try {
        // Upload video to Firestore with disposal category
        await FirebaseFirestore.instance.collection('videos').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'videoUrl': _videoUrl,
          'disposalCategory': _selectedCategory!.value, // Save category
          'uploadedAt': FieldValue.serverTimestamp(),
          'userId': 'current_user_id', // Replace with actual user ID
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video uploaded successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video'),
        backgroundColor: Colors.green,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Video Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Video Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Video Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // DISPOSAL CATEGORY SELECTOR (Chip Style)
            CategorySelectorWidget(
              initialCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),

            // OR use dropdown style:
            // CategoryDropdownSelector(
            //   selectedCategory: _selectedCategory,
            //   onChanged: (category) {
            //     setState(() {
            //       _selectedCategory = category;
            //     });
            //   },
            // ),

            const SizedBox(height: 24),

            // Upload Button
            ElevatedButton(
              onPressed: _selectedCategory != null ? _uploadVideo : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Upload Video',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// =============================================================================
// EXAMPLE 2: Add to Video Player Page (Trivia Section)
// =============================================================================

class VideoPlayerWithTriviaExample extends StatelessWidget {
  final String videoId;

  const VideoPlayerWithTriviaExample({
    super.key,
    required this.videoId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('videos')
            .doc(videoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final videoData = snapshot.data!.data() as Map<String, dynamic>?;
          if (videoData == null) {
            return const Center(child: Text('Video not found'));
          }

          // Get disposal category from Firestore
          final categoryString = videoData['disposalCategory'] as String?;
          DisposalCategory? category;

          if (categoryString != null) {
            category = DisposalCategoryExtension.fromString(categoryString);
          }

          return CustomScrollView(
            slivers: [
              // Video Player (your existing implementation)
              SliverToBoxAdapter(
                child: Container(
                  height: 250,
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'VIDEO PLAYER HERE',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),

              // Video Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        videoData['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        videoData['description'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              // DISPOSAL TRIVIA SECTION
              if (category != null)
                SliverToBoxAdapter(
                  child: DisposalTriviaWidget(
                    category: category,
                    showFullInfo: true, // Set to false for compact view
                  ),
                ),

              // Other sections (comments, related videos, etc.)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text('Comments and other content...'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// EXAMPLE 3: Compact Trivia for Small Spaces
// =============================================================================

class VideoCardWithTrivia extends StatelessWidget {
  final String videoId;
  final String title;
  final String thumbnail;
  final String categoryString;

  const VideoCardWithTrivia({
    super.key,
    required this.videoId,
    required this.title,
    required this.thumbnail,
    required this.categoryString,
  });

  @override
  Widget build(BuildContext context) {
    final category = DisposalCategoryExtension.fromString(categoryString);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video thumbnail
          Image.network(
            thumbnail,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Compact trivia display
                CompactDisposalTrivia(category: category),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EXAMPLE 4: Update Existing Video with Category
// =============================================================================

class UpdateVideoCategoryExample {
  /// Update an existing video with disposal category
  static Future<void> updateVideoCategory(
    String videoId,
    DisposalCategory category,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('videos')
          .doc(videoId)
          .update({
        'disposalCategory': category.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Video category updated successfully');
    } catch (e) {
      print('Error updating video category: $e');
      rethrow;
    }
  }

  /// Batch update multiple videos
  static Future<void> batchUpdateCategories(
    Map<String, DisposalCategory> videoCategories,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final entry in videoCategories.entries) {
      final docRef =
          FirebaseFirestore.instance.collection('videos').doc(entry.key);

      batch.update(docRef, {
        'disposalCategory': entry.value.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    print('Batch update completed');
  }
}

// =============================================================================
// EXAMPLE 5: Query Videos by Category
// =============================================================================

class VideoByCategoryPage extends StatelessWidget {
  final DisposalCategory category;

  const VideoByCategoryPage({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${category.name} Videos'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('videos')
            .where('disposalCategory', isEqualTo: category.value)
            .orderBy('uploadedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final videos = snapshot.data!.docs;

          if (videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.icon,
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${category.name} videos yet',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index].data() as Map<String, dynamic>;

              return VideoCardWithTrivia(
                videoId: videos[index].id,
                title: video['title'] ?? 'Untitled',
                thumbnail: video['thumbnailUrl'] ?? '',
                categoryString: video['disposalCategory'] ?? '',
              );
            },
          );
        },
      ),
    );
  }
}

// =============================================================================
// EXAMPLE 6: Firestore Security Rules
// =============================================================================

/*
Add these to your Firestore security rules:

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /videos/{videoId} {
      // Allow read for all users
      allow read: if true;
      
      // Allow create only for authenticated users with required fields
      allow create: if request.auth != null 
                    && request.resource.data.keys().hasAll(['title', 'disposalCategory'])
                    && request.resource.data.disposalCategory in [
                        'plasticBottles', 
                        'tires', 
                        'rubberBands', 
                        'cans', 
                        'cartons', 
                        'paper', 
                        'unusedClothes'
                      ];
      
      // Allow update only by video owner
      allow update: if request.auth != null 
                    && request.auth.uid == resource.data.userId;
      
      // Allow delete only by video owner
      allow delete: if request.auth != null 
                    && request.auth.uid == resource.data.userId;
    }
  }
}
*/

// =============================================================================
// EXAMPLE 7: Get Disposal Info for Display
// =============================================================================

class DisposalInfoExample {
  /// Get and display disposal information
  static void showDisposalInfo(
      BuildContext context, DisposalCategory category) {
    final info = DisposalGuideService.getDisposalInfo(category);

    if (info == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(child: Text(info.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(info.description),
              const SizedBox(height: 16),
              const Text(
                'Quick Steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...info.steps.take(3).map((step) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $step'),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to full disposal guide
            },
            child: const Text('View Full Guide'),
          ),
        ],
      ),
    );
  }

  /// Get trivia text for sharing
  static String getShareableTrivia(DisposalCategory category) {
    return DisposalGuideService.getTriviaText(category);
  }
}
