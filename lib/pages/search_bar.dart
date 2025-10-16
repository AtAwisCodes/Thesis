import 'dart:async';
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
  Timer? _debounceTimer;
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
          // If there's a query, keep it; if not, clear search
          if (query.trim().isNotEmpty) {
            Provider.of<YtVideoviewModel>(context, listen: false)
                .setSearchQuery(query.trim());
            print('DEBUG: Back button pressed with query: "${query.trim()}"');
          } else {
            Provider.of<YtVideoviewModel>(context, listen: false).clearSearch();
            print('DEBUG: Back button pressed, search cleared');
          }
          close(context, query);
        },
      );

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Set query and close to show results
              if (query.trim().isNotEmpty) {
                Provider.of<YtVideoviewModel>(context, listen: false)
                    .setSearchQuery(query.trim());
                print(
                    'DEBUG: Search button pressed, query set: "${query.trim()}"');
              }
              close(context, query);
            },
          ),
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
      Provider.of<YtVideoviewModel>(context, listen: false)
          .setSearchQuery(query.trim());
      print('DEBUG: Setting search query in buildResults: "${query.trim()}"');
    }
    close(context, query);
    return Container();
  }

  void _updateSearchQuery(BuildContext context, String searchQuery) {
    _debounceTimer?.cancel();

    // Only update the search query for real-time filtering, don't auto-close
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (searchQuery.trim().isNotEmpty) {
        Provider.of<YtVideoviewModel>(context, listen: false)
            .setSearchQuery(searchQuery.trim());
        print('DEBUG: Real-time search query updated: "${searchQuery.trim()}"');
      } else {
        Provider.of<YtVideoviewModel>(context, listen: false).clearSearch();
        print('DEBUG: Search query cleared');
      }
    });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    _updateSearchQuery(context, query);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              query.isEmpty ? Icons.search : Icons.filter_list,
              size: 64,
              color: Colors.green.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? "Type to search for videos"
                  : "Searching for '$query'...",
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
                  : "Results will show automatically",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.withOpacity(0.6)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Results will appear automatically...",
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
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
