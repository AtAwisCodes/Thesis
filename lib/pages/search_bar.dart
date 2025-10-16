import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rexplore/viewmodel/yt_videoview_model.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _Search();
}

// SearchBar Class
class MySearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Search videos...';

  @override
  TextInputAction get textInputAction => TextInputAction.search;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
            color: Colors.black, fontWeight: FontWeight.w500, fontSize: 18),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.green),
      ),
    );
  }

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Only clear if user presses back with empty query (canceling search)
          // If there's a query, it means they want to keep it
          if (query.isEmpty) {
            Provider.of<YtVideoviewModel>(context, listen: false).clearSearch();
            print(
                'DEBUG: Back button pressed with empty query, cleared search');
          } else {
            print('DEBUG: Back button pressed with query, keeping it');
          }
          close(context, null);
        },
      );

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              query = '';
              Provider.of<YtVideoviewModel>(context, listen: false)
                  .clearSearch();
              print('DEBUG: Search cleared via clear button');
            },
          ),
      ];

  @override
  Widget buildResults(BuildContext context) {
    // CRITICAL: Set the search query BEFORE closing
    if (query.trim().isNotEmpty) {
      final trimmedQuery = query.trim();
      print('DEBUG: buildResults called with query: "$trimmedQuery"');

      final viewModel = Provider.of<YtVideoviewModel>(context, listen: false);
      viewModel.setSearchQuery(trimmedQuery);

      print(
          'DEBUG: After setSearchQuery, viewModel.searchQuery = "${viewModel.searchQuery}"');

      // Small delay to ensure state is updated before closing
      Future.microtask(() {
        print('DEBUG: Closing search interface');
        close(context, query);
      });
    } else {
      close(context, query);
    }
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              query.isEmpty ? Icons.search : Icons.keyboard,
              size: 64,
              color: Colors.green.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? "Type to search for videos"
                  : "Press Enter to search for '$query'",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? "Search by title, description, or channel name"
                  : "Tap the Enter key on your keyboard",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (query.isNotEmpty) ...[],
          ],
        ),
      ),
    );
  }
}

class _Search extends State<Search> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            showSearch(context: context, delegate: MySearchDelegate());
          },
          icon: const Icon(Icons.search, color: Colors.white),
          label: const Text("Search Items",
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ),
    );
  }
}
