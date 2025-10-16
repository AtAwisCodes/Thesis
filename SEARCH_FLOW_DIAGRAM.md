# Search Flow Diagram

## Complete Search Flow

```
User Action                  Code Execution                           UI Response
-----------                  --------------                           -----------

[Open Search]
    |
    v
[Type "plastic"]
    |
    v
[Press ENTER] ---------> buildResults() called
                              |
                              v
                         setSearchQuery("plastic") 
                              |
                              v
                         YtVideoviewModel.searchQuery = "plastic"
                              |
                              v
                         notifyListeners() ---------> context.watch() detects change
                              |                              |
                              v                              v
                         close(context)           VideosPage rebuilds
                              |                              |
                              v                              v
                         Return to home           Filters combinedList
                                                             |
                                                             v
                                                   Creates filteredList
                                                             |
                                                             v
                                                   ListView.builder renders
                                                             |
                              +------------------------------+
                              |
                              v
                    [Shows filtered videos + green banner]
```

## State Management Flow

```
search_bar.dart (UI Layer)
    |
    | Provider.of<YtVideoviewModel>(context, listen: false)
    |     .setSearchQuery(query.trim())
    v
yt_videoview_model.dart (State Layer)
    |
    | searchQuery = query
    | notifyListeners()
    |
    +---> videos_page.dart (Consumer 1)
    |         |
    |         | context.watch<YtVideoviewModel>().searchQuery
    |         v
    |     Rebuilds with filtered videos
    |
    +---> home_page.dart (Consumer 2)
              |
              | ytVideoViewModel.searchQuery.isNotEmpty
              v
          Shows green banner with clear button
```

## Data Flow in videos_page.dart

```
1. StreamBuilder (Firestore)
        |
        v
   uploadedVideos: List<Map>
        |
        +---> combinedList
        |           |
2. YT Playlist      | (merge)
        |           |
        v           v
   playlistItems ---+
        
        combinedList = [...uploaded, ...youtube]
              |
              v
        searchQuery.isEmpty?
              |
        +-----+-----+
        |           |
      YES          NO
        |           |
        v           v
   filteredList  filteredList = combinedList.where(...)
   = combinedList        |
                         v
                   Check title/description/channelName
                         |
                         v
                   Keep only matches
                         |
                         v
                   filteredList (smaller list)
        
        Both paths lead to:
              |
              v
        ListView.builder(itemCount: filteredList.length)
              |
              v
        Render each video card
```

## Key Components

### 1. Search Delegate (search_bar.dart)
- **buildLeading**: Back button (keeps query if not empty)
- **buildActions**: Clear button (clears query + search)
- **buildResults**: ENTER key handler (sets query + closes)
- **buildSuggestions**: Instructions UI

### 2. View Model (yt_videoview_model.dart)
- **searchQuery**: String property (default: '')
- **setSearchQuery()**: Sets query + notifies listeners
- **clearSearch()**: Clears query + notifies listeners
- **notifyListeners()**: Triggers rebuild in all consumers

### 3. Videos Page (videos_page.dart)
- **context.watch()**: Listens for searchQuery changes
- **Consumer**: Rebuilds on notifyListeners()
- **Filtering logic**: Compares searchQuery with video data
- **Debug output**: Prints every step

### 4. Home Page (home_page.dart)
- **Consumer**: Listens for searchQuery changes
- **Green banner**: Shows when searchQuery.isNotEmpty
- **Clear button**: Calls clearSearch()

## Debug Checkpoints

```
Checkpoint 1: Query Submission
[search_bar.dart line 70]
print('DEBUG: Setting search query in buildResults: "${query.trim()}"')
✅ Confirms Enter key was pressed

Checkpoint 2: View Model Update
[yt_videoview_model.dart line 40]
print('DEBUG YtVideoviewModel.setSearchQuery: searchQuery is now "$searchQuery"')
✅ Confirms Provider connection works

Checkpoint 3: Notify Listeners
[yt_videoview_model.dart line 42]
print('DEBUG YtVideoviewModel.setSearchQuery: notifyListeners() called')
✅ Confirms state change notification sent

Checkpoint 4: Videos Page Rebuild
[videos_page.dart line 50]
print('DEBUG VideosPage: searchQuery="$searchQuery", combinedList.length=${combinedList.length}')
✅ Confirms rebuild triggered

Checkpoint 5: Filtering
[videos_page.dart line 84]
print('DEBUG VideosPage: filteredList.length=${filteredList.length}')
✅ Confirms filtering completed

Checkpoint 6: Rendering
[videos_page.dart line 181]
print('DEBUG: Rendering item $index, type: ${item["type"]}')
✅ Confirms UI rendering filtered items
```

## What Each Debug Message Means

1. **"DEBUG: Setting search query in buildResults"**
   - Enter key was pressed successfully
   - Query is about to be saved

2. **"DEBUG YtVideoviewModel.setSearchQuery: searchQuery is now"**
   - View model received the query
   - Property was updated

3. **"DEBUG YtVideoviewModel.setSearchQuery: notifyListeners() called"**
   - All listeners are being notified
   - Rebuild should happen next

4. **"DEBUG VideosPage: searchQuery="**
   - VideosPage rebuild started
   - Using this search query for filtering

5. **"DEBUG UPLOADED:" / "DEBUG YOUTUBE:"**
   - Each video is being checked
   - Shows if it matches the search

6. **"DEBUG VideosPage: filteredList.length="**
   - Total matching videos found
   - This count should show in UI

7. **"DEBUG: Rendering item X"**
   - UI is actually drawing the video card
   - Should see one per filtered video
