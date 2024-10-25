import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_tracker/providers/media_provider.dart';
import 'package:media_tracker/screens/media_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_tracker/screens/home_screen.dart';

class MediaListScreen extends StatefulWidget {
  final MediaType type;

  const MediaListScreen({
    super.key,
    required this.type,
  });

  @override
  State<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends State<MediaListScreen> with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  TabController? _tabController;
  Timer? _debounce;

  final ValueNotifier<bool> _showScrollButtons = ValueNotifier<bool>(false);
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupListeners();
    _initializeData();
  }

  void _initializeControllers() {
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    if (widget.type == MediaType.watchlist) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  void _setupListeners() {
    _scrollController.addListener(_onScroll);

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 500),
            () => _searchQuery.value = _searchController.text,
      );
    });

    _tabController?.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      _showScrollButtons.value = _scrollController.offset > 100;
    }
  }

  Future<void> _initializeData() async {
    try {
      await context.read<MediaProvider>().refreshMedia(widget.type.value);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading data: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _scrollToPosition(double position) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToTop() => _scrollToPosition(0);
  void _scrollToBottom() => _scrollToPosition(_scrollController.position.maxScrollExtent);

  Icon _getMediaTypeIcon(MediaType type) {
    switch (type) {
      case MediaType.movie:
        return const Icon(Icons.movie);
      case MediaType.series:
        return const Icon(Icons.tv);
      case MediaType.anime:
        return const Icon(Icons.animation);
      default:
        return const Icon(Icons.list);
    }
  }

  List<dynamic> _getFilteredList(MediaProvider mediaProvider, {MediaType? subType}) {
    final List<dynamic> mediaList = _getMediaList(mediaProvider, subType);

    if (_searchQuery.value.isEmpty) return mediaList;

    return mediaList.where((item) =>
        item.title.toLowerCase().contains(_searchQuery.value.toLowerCase())
    ).toList();
  }

  List<dynamic> _getMediaList(MediaProvider mediaProvider, MediaType? subType) {
    if (widget.type == MediaType.watchlist && subType != null) {
      return mediaProvider.watchlist.where((item) =>
      item.type == 'watchlist' && item.originalType == subType.value
      ).toList();
    }
    switch (widget.type) {
      case MediaType.movie:
        return mediaProvider.movies;
      case MediaType.series:
        return mediaProvider.tvShows;
      case MediaType.anime:
        return mediaProvider.anime;
      case MediaType.watchlist:
        return mediaProvider.watchlist;
    }
  }

  Widget _buildEmptyState(MediaType? subType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _getMediaTypeIcon(subType ?? widget.type),
          const SizedBox(height: 16),
          Text(
            'No ${(subType ?? widget.type).displayName} items found.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaList(MediaProvider mediaProvider, {MediaType? subType}) {
    final filteredItems = _getFilteredList(mediaProvider, subType: subType);

    if (filteredItems.isEmpty) {
      return _buildEmptyState(subType);
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredItems.length,
      itemBuilder: (context, index) =>
          _buildMediaItem(filteredItems[index], mediaProvider),
    );
  }

  Widget _buildMediaItem(dynamic item, MediaProvider mediaProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: _buildLeadingImage(item),
          title: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(item.year.toString()),
          trailing: _buildRatingChips(item),
          onTap: () => _navigateToDetail(item, mediaProvider),
        ),
      ),
    );
  }

  Widget _buildLeadingImage(dynamic item) {
    if (item.posterUrl == null) {
      MediaType type = MediaType.values.firstWhere(
            (t) => t.value == (item.originalType ?? item.type),
        orElse: () => MediaType.movie,
      );
      return _getMediaTypeIcon(type);
    }

    return CachedNetworkImage(
      imageUrl: item.posterUrl!,
      placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
      width: 50,
      height: 75,
      fit: BoxFit.cover,
    );
  }

  Widget _buildRatingChips(dynamic item) {
    return Wrap(
      spacing: 8,
      children: [
        if (item.userRating != null)
          _buildRatingChip(
            item.userRating!.toStringAsFixed(1),
            Colors.blue,
          ),
        if (item.imdbRating != null)
          _buildRatingChip(
            'IMDb: ${item.imdbRating}',
            Colors.amber,
          ),
      ],
    );
  }

  Widget _buildRatingChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Future<void> _navigateToDetail(dynamic item, MediaProvider mediaProvider) async {
    final isUpdated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailScreen(item: item),
      ),
    );

    if (mounted && isUpdated == true) {
      await _initializeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.type.displayName} List'),
        bottom: widget.type == MediaType.watchlist && _tabController != null
            ? TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Movies'),
            Tab(text: 'TV Shows'),
          ],
        )
            : null,
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildScrollButtons(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _initializeData,
              child: ValueListenableBuilder<String>(
                valueListenable: _searchQuery,
                builder: (context, query, _) {
                  return Consumer<MediaProvider>(
                    builder: (context, mediaProvider, _) {
                      if (widget.type == MediaType.watchlist && _tabController != null) {
                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMediaList(mediaProvider, subType: MediaType.movie),
                            _buildMediaList(mediaProvider, subType: MediaType.series),
                          ],
                        );
                      }
                      return _buildMediaList(mediaProvider);
                    },
                  );
                },
              ),
            ),
          ),


        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ValueListenableBuilder<String>(
        valueListenable: _searchQuery,
        builder: (context, query, _) {
          return TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _searchQuery.value = '';
                },
              )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildScrollButtons() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showScrollButtons,
      builder: (context, showButtons, _) {
        return AnimatedOpacity(
          opacity: showButtons ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward),
                onPressed: _scrollToTop,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward),
                onPressed: _scrollToBottom,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _tabController?.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}