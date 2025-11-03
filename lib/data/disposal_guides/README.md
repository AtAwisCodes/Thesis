# Disposal Guide System Documentation

## Overview
This system provides comprehensive disposal information for 7 categories of recyclable/reusable items. It integrates seamlessly with video uploads and displays educational content in the video player's trivia section.

## Categories Included
1. 🍾 **Plastic Bottles** - Recycling and proper disposal
2. 🛞 **Tires** - Hazardous waste handling
3. ⭕ **Rubber Bands** - Reuse and disposal
4. 🥫 **Cans** - Aluminum and steel recycling
5. 📦 **Cartons** - Multi-material recycling
6. 📄 **Paper** - Paper recycling guidelines
7. 👕 **Unused Clothes** - Textile donation and recycling

## File Structure
```
lib/
├── data/
│   └── disposal_guides/
│       ├── disposal_categories.dart      # Category enum and extensions
│       ├── disposal_info_data.dart       # Comprehensive disposal information
│       └── README.md                     # This file
├── components/
│   ├── category_selector_widget.dart     # Upload page selector
│   └── disposal_trivia_widget.dart       # Video player display
└── examples/
    └── disposal_integration_example.dart # Integration examples
```

## Quick Start

### 1. Add Category Selection to Video Upload

```dart
import 'package:rexplore/components/category_selector_widget.dart';
import 'package:rexplore/data/disposal_guides/disposal_categories.dart';

class YourUploadPage extends StatefulWidget {
  // ... your code
  
  DisposalCategory? _selectedCategory;
  
  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          // Your existing fields (title, description, etc.)
          
          // Add category selector
          CategorySelectorWidget(
            initialCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          
          // Your upload button
        ],
      ),
    );
  }
  
  Future<void> _uploadVideo() async {
    await FirebaseFirestore.instance.collection('videos').add({
      'title': _titleController.text,
      // ... other fields
      'disposalCategory': _selectedCategory!.value, // Save category
      'uploadedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

### 2. Display Disposal Information in Video Player

```dart
import 'package:rexplore/components/disposal_trivia_widget.dart';
import 'package:rexplore/data/disposal_guides/disposal_categories.dart';

class YourVideoPlayerPage extends StatelessWidget {
  final String videoId;
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .doc(videoId)
          .snapshots(),
      builder: (context, snapshot) {
        final videoData = snapshot.data!.data() as Map<String, dynamic>;
        final categoryString = videoData['disposalCategory'] as String?;
        
        if (categoryString != null) {
          final category = DisposalCategoryExtension.fromString(categoryString);
          
          return Column(
            children: [
              // Your video player
              
              // Video info
              
              // TRIVIA SECTION - Add this
              DisposalTriviaWidget(
                category: category,
                showFullInfo: true,
              ),
              
              // Comments, etc.
            ],
          );
        }
        
        return YourVideoPlayerWidget();
      },
    );
  }
}
```

### 3. Alternative: Compact Trivia Display

For smaller spaces or card views:

```dart
import 'package:rexplore/components/disposal_trivia_widget.dart';

CompactDisposalTrivia(
  category: category,
)
```

### 4. Alternative: Dropdown Selector

For more compact upload forms:

```dart
import 'package:rexplore/components/category_selector_widget.dart';

CategoryDropdownSelector(
  selectedCategory: _selectedCategory,
  onChanged: (category) {
    setState(() {
      _selectedCategory = category;
    });
  },
)
```

## Firestore Data Structure

### Video Document Structure
```json
{
  "videoId": "auto_generated",
  "title": "How to Recycle Plastic Bottles",
  "description": "...",
  "videoUrl": "https://...",
  "thumbnailUrl": "https://...",
  "disposalCategory": "plasticBottles",
  "userId": "user_123",
  "uploadedAt": "timestamp",
  "views": 0
}
```

### Required Firestore Index
Create a composite index for querying:
- Collection: `videos`
- Fields: `disposalCategory` (Ascending), `uploadedAt` (Descending)

### Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /videos/{videoId} {
      allow read: if true;
      
      allow create: if request.auth != null 
                    && request.resource.data.keys().hasAll(['title', 'disposalCategory'])
                    && request.resource.data.disposalCategory in [
                        'plasticBottles', 'tires', 'rubberBands', 
                        'cans', 'cartons', 'paper', 'unusedClothes'
                      ];
      
      allow update, delete: if request.auth != null 
                             && request.auth.uid == resource.data.userId;
    }
  }
}
```

## API Reference

### DisposalCategory Enum
```dart
enum DisposalCategory {
  plasticBottles,
  tires,
  rubberBands,
  cans,
  cartons,
  paper,
  unusedClothes,
}
```

### DisposalCategoryExtension Methods
```dart
// Get display name
category.name → "Plastic Bottles"

// Get emoji icon
category.icon → "🍾"

// Get string value for storage
category.value → "plasticBottles"

// Convert from string
DisposalCategoryExtension.fromString('plasticBottles') → DisposalCategory.plasticBottles
```

### DisposalGuideService Methods
```dart
// Get full disposal information
DisposalGuideService.getDisposalInfo(category) → DisposalInfo

// Get info by string value
DisposalGuideService.getDisposalInfoByString('plasticBottles') → DisposalInfo

// Get formatted trivia text for display
DisposalGuideService.getTriviaText(category) → String

// Get compact trivia
DisposalGuideService.getShortTrivia(category) → String

// Get all categories
DisposalGuideService.getAllCategories() → List<DisposalCategory>
```

### DisposalInfo Properties
```dart
class DisposalInfo {
  final DisposalCategory category;
  final String title;
  final String description;
  final List<String> steps;          // Disposal steps
  final List<String> dosList;        // Best practices
  final List<String> dontsList;      // Things to avoid
  final String environmentalImpact;  // Environmental facts
  final String funFact;              // Interesting trivia
}
```

## Integration Locations

### Where to Add Category Selector
Find your video upload page and add the `CategorySelectorWidget` in the form where users input video details. Common locations:

1. **Upload Page**: `lib/pages/upload_video_page.dart`
2. **Create Content Page**: `lib/pages/create_content.dart`
3. **Add Video Form**: `lib/components/video_upload_form.dart`

### Where to Display Trivia
Find your video player page and add the `DisposalTriviaWidget` below the video player. Common locations:

1. **Video Player Page**: `lib/pages/video_player_page.dart`
2. **Video Details Page**: `lib/pages/video_details.dart`
3. **Watch Page**: `lib/pages/watch_video.dart`

Look for sections labeled:
- "Trivia"
- "About"
- "Description"
- "Information"

## Customization

### Modify Disposal Information
Edit `lib/data/disposal_guides/disposal_info_data.dart`:

```dart
DisposalCategory.plasticBottles: DisposalInfo(
  category: DisposalCategory.plasticBottles,
  title: 'Your Custom Title',
  description: 'Your custom description...',
  steps: [
    'Custom step 1',
    'Custom step 2',
  ],
  // ... other fields
),
```

### Add New Categories
1. Add to enum in `disposal_categories.dart`:
```dart
enum DisposalCategory {
  plasticBottles,
  // ... existing categories
  yourNewCategory, // Add here
}
```

2. Add display info to extension:
```dart
extension DisposalCategoryExtension on DisposalCategory {
  String get name {
    switch (this) {
      // ... existing cases
      case DisposalCategory.yourNewCategory:
        return 'Your Category Name';
    }
  }
}
```

3. Add disposal information in `disposal_info_data.dart`:
```dart
DisposalCategory.yourNewCategory: DisposalInfo(
  // ... your information
),
```

### Customize Widget Appearance
Edit `disposal_trivia_widget.dart` to change colors, fonts, layouts, etc.

## Testing

### Test Category Selection
```dart
void testCategorySelector() {
  DisposalCategory category = DisposalCategory.plasticBottles;
  print('Name: ${category.name}');
  print('Icon: ${category.icon}');
  print('Value: ${category.value}');
}
```

### Test Disposal Info Retrieval
```dart
void testDisposalInfo() {
  final info = DisposalGuideService.getDisposalInfo(
    DisposalCategory.plasticBottles
  );
  
  print('Title: ${info?.title}');
  print('Steps: ${info?.steps.length}');
  print('Trivia: ${DisposalGuideService.getTriviaText(
    DisposalCategory.plasticBottles
  )}');
}
```

## Troubleshooting

### Category not saving to Firestore
- Ensure you're using `category.value` not `category.toString()`
- Check Firestore security rules allow the `disposalCategory` field

### Trivia not displaying
- Verify `disposalCategory` field exists in video document
- Check the string matches one of the enum values exactly
- Ensure `DisposalTriviaWidget` is in the widget tree

### Category selector not showing
- Import the widget: `import 'package:rexplore/components/category_selector_widget.dart';`
- Check if `DisposalCategory.values` returns categories

## Features

### Educational Content
Each category includes:
- ✅ Step-by-step disposal instructions
- ✅ Do's and Don'ts lists
- ✅ Environmental impact facts
- ✅ Fun facts and trivia
- ✅ Proper recycling guidelines

### User Experience
- 🎨 Clean, modern UI with icons
- 📱 Responsive design
- 🔄 Expandable detailed information
- 🎯 Easy category selection
- 📊 Visual feedback

### Developer Features
- 🔌 Easy integration
- 📦 Modular components
- 🔧 Customizable
- 📝 Well-documented
- 🧪 Testable

## Future Enhancements

Potential additions:
- [ ] Localization (multiple languages)
- [ ] Video tutorials for each category
- [ ] Nearby recycling center finder
- [ ] Carbon footprint calculator
- [ ] Gamification (badges for proper disposal)
- [ ] Social sharing of disposal tips
- [ ] AI-powered category suggestion from video content

## Support

For issues or questions:
1. Check the integration examples in `lib/examples/disposal_integration_example.dart`
2. Review this documentation
3. Check Firestore console for data structure
4. Review Flutter debug console for errors

## License

This disposal guide system is part of the ReXplore project.
