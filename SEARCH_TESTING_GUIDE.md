# Search Functionality Testing Guide

## How Search Should Work

1. **User opens search**: Tap the search icon in the app bar
2. **Type a query**: e.g., "plastic" or "recycle"
3. **Press Enter**: On keyboard (not a button)
4. **Return to home page**: Should see filtered videos with a green banner

## Expected Console Debug Output

When you test the search, you should see this sequence in the console:

```
DEBUG: Setting search query in buildResults: "plastic"
DEBUG YtVideoviewModel.setSearchQuery: searchQuery is now "plastic"
DEBUG YtVideoviewModel.setSearchQuery: notifyListeners() called
DEBUG VideosPage: searchQuery="plastic", combinedList.length=50
DEBUG UPLOADED: title="...", description="...", searchQuery="plastic", matches=true
DEBUG YOUTUBE: title="...", channelName="...", searchQuery="plastic", matches=false
DEBUG VideosPage: filteredList.length=5
DEBUG: Rendering item 0, type: uploaded
DEBUG: Uploaded video title: ...
```

## What to Check If Search Doesn't Work

### 1. Check if query is being set
Look for: `DEBUG: Setting search query in buildResults: "your query"`
- ✅ If you see this: Query is being submitted correctly
- ❌ If you don't see this: buildResults() is not being called (Enter key not working)

### 2. Check if view model is updating
Look for: `DEBUG YtVideoviewModel.setSearchQuery: searchQuery is now "your query"`
- ✅ If you see this: View model is receiving the query
- ❌ If you don't see this: Provider connection issue

### 3. Check if notifyListeners is called
Look for: `DEBUG YtVideoviewModel.setSearchQuery: notifyListeners() called`
- ✅ If you see this: State change notification is being triggered
- ❌ If you don't see this: Something is wrong in setSearchQuery method

### 4. Check if VideosPage is rebuilding
Look for: `DEBUG VideosPage: searchQuery="your query", combinedList.length=X`
- ✅ If you see this with your query: VideosPage is rebuilding with search
- ❌ If searchQuery is empty: context.watch() is not triggering rebuild
- ❌ If you don't see this at all: VideosPage is not rebuilding

### 5. Check if videos are being filtered
Look for: `DEBUG VideosPage: filteredList.length=Y`
- ✅ If Y > 0: Videos match your search
- ⚠️ If Y = 0: No videos match (try a different query)

### 6. Check if green banner appears
Look at the top of the home page:
- ✅ If you see green banner with "Filtering by: 'your query'": UI is showing search state
- ❌ If no banner: Consumer in home_page.dart not updating

## Test Cases

### Test Case 1: Basic Search
1. Open search
2. Type "plastic"
3. Press Enter
4. **Expected**: See videos about plastic, green banner shows "Filtering by: 'plastic'"

### Test Case 2: Clear Search via Banner
1. After Test Case 1
2. Click X button in green banner
3. **Expected**: Banner disappears, all videos show again

### Test Case 3: Clear Search via Search Bar
1. Open search
2. Type something
3. Click X in search bar
4. **Expected**: Text clears, any previous filter remains until you close search

### Test Case 4: Cancel Search
1. Open search
2. Don't type anything
3. Press back arrow
4. **Expected**: Return to previous state (keeps any existing filter)

### Test Case 5: No Results
1. Open search
2. Type "xyzabc123" (nonsense)
3. Press Enter
4. **Expected**: See "No videos found" message with clear button

## File Connections

### search_bar.dart → yt_videoview_model.dart
```dart
// In buildResults()
Provider.of<YtVideoviewModel>(context, listen: false).setSearchQuery(query.trim());
```

### yt_videoview_model.dart → videos_page.dart
```dart
// In videos_page.dart build()
final searchQuery = context.watch<YtVideoviewModel>().searchQuery;
```

### yt_videoview_model.dart → home_page.dart
```dart
// In home_page.dart Consumer
Consumer<YtVideoviewModel>(
  builder: (context, ytVideoViewModel, _) {
    if (ytVideoViewModel.searchQuery.isNotEmpty) {
      // Show green banner
    }
  }
)
```

## Common Issues and Fixes

### Issue: Videos not filtering after Enter
**Cause**: buildResults() called before query is set
**Fix**: Already fixed - setSearchQuery() called BEFORE close()

### Issue: Search clears when returning to home
**Cause**: buildLeading() was clearing on back
**Fix**: Already fixed - only clears if query is empty

### Issue: No rebuild after search
**Cause**: Missing context.watch() in videos_page.dart
**Fix**: Already added - line 31 of videos_page.dart

### Issue: Banner not showing
**Cause**: Consumer not listening to changes
**Fix**: Consumer is set up correctly in home_page.dart

## Debug Output Location

All debug output goes to:
- **VS Code**: Debug Console panel (Ctrl+Shift+Y)
- **Android Studio**: Run panel at bottom
- **Command Line**: If running `flutter run` in terminal

Make sure to look at the console AFTER pressing Enter to see the debug sequence.
