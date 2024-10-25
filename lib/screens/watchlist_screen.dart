import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_tracker/models/media_item.dart';
import 'package:media_tracker/providers/media_provider.dart';
import 'package:media_tracker/screens/watchlist_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MediaItem> _filterWatchlist(List<MediaItem> items, String originalType) {
    return items
        .where((item) =>
    item.originalType == originalType &&
        item.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Watchlist'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Movies'),
            Tab(text: 'TV Shows'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Watchlist',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Consumer<MediaProvider>(
              builder: (context, mediaProvider, child) {
                final filteredMovies = _filterWatchlist(mediaProvider.watchlist, 'movie');
                final filteredSeries = _filterWatchlist(mediaProvider.watchlist, 'series');

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWatchlistTab(filteredMovies, 'movie'),
                    _buildWatchlistTab(filteredSeries, 'series'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistTab(List<MediaItem> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'movie' ? Icons.movie_outlined : Icons.tv_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type == 'movie' ? 'movies' : 'TV shows'} in your watchlist',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<MediaProvider>().refreshMedia('watchlist');
      },
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: item.posterUrl != null
                  ? Hero(
                tag: 'watchlist_poster_${item.id}',
                child: CachedNetworkImage(
                  imageUrl: item.posterUrl!,
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                  const CircularProgressIndicator(),
                  errorWidget: (context, url, error) =>
                  const Icon(Icons.error),
                ),
              )
                  : Icon(
                type == 'movie' ? Icons.movie : Icons.tv,
                size: 40,
              ),
              title: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('${item.year}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WatchlistDetailScreen(item: item),
                  ),
                );
                if (result == true) {
                  if (!mounted) return;
                  context.read<MediaProvider>().refreshMedia('watchlist');
                }
              },
            ),
          );
        },
      ),
    );
  }
}