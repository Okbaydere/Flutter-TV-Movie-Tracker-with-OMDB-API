import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_tracker/models/media_item.dart';
import 'package:media_tracker/providers/media_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_tracker/screens/search_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MediaItem> _searchResults = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for movies, TV shows, or anime',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.blue),
                  onPressed: () => _performSearch(context),
                ),
              ),
              onSubmitted: (_) => _performSearch(context),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                  ? const Center(
                child: Text(
                  'No results found. Try different keywords.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: Hero(
                        tag: 'poster-${item.imdbID}', // Hero tag
                        child: item.posterUrl != null
                            ? CachedNetworkImage(
                          imageUrl: item.posterUrl!,
                          placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                          height: 50,
                          width: 50,
                        )
                            : const Icon(Icons.movie),
                      ),
                      title: Text(item.title),
                      subtitle: Text('${item.year} - ${item.type}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          _addToWatchlist(context, item);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SearchDetailScreen(item: item),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performSearch(BuildContext context) async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _searchResults = []; // Clear previous results
      });
      try {
        final results = await Provider.of<MediaProvider>(context, listen: false)
            .searchMedia(query);
        setState(() {
          _searchResults = results;
        });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addToWatchlist(BuildContext context, MediaItem item) {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    try {
      if (mediaProvider.watchlist.contains(item)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.title} is already in your watchlist')),
        );
      } else {
        mediaProvider.addMediaItem(item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.title} added to watchlist')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to watchlist: $error')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

