import 'package:flutter/material.dart';
import 'package:media_tracker/models/media_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:media_tracker/providers/media_provider.dart';
import 'package:media_tracker/services/omdb_service.dart';

class SearchDetailScreen extends StatefulWidget {
  final MediaItem item;

  const SearchDetailScreen({super.key, required this.item});

  @override
  State<SearchDetailScreen> createState() => _SearchDetailScreenState();
}

class _SearchDetailScreenState extends State<SearchDetailScreen> {
  late final Future<MediaItem?> _detailedItem;
  String _selectedType = 'watchlist';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _detailedItem = OmdbService().getMediaDetails(widget.item.imdbID ?? '');
  }

  // Extracted widget for better organization
  Widget _buildInfoRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();

    // Convert the value to string and check if it's empty
    final stringValue = value.toString();
    if (stringValue.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$label: $stringValue',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  // Extracted method for radio buttons
  Widget _buildRadioButtons() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Add to Watchlist'),
            value: 'watchlist',
            groupValue: _selectedType,
            onChanged: (value) => setState(() => _selectedType = value!),
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Mark as Watched'),
            value: widget.item.type,
            groupValue: _selectedType,
            onChanged: (value) => setState(() => _selectedType = value!),
          ),
        ),
      ],
    );
  }

  Future<void> _addToList(BuildContext context, MediaItem item) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

      final updatedItem = MediaItem(
        title: item.title,
        type: _selectedType,
        originalType: _selectedType == 'watchlist' ? item.type : null,
        year: item.year,
        posterUrl: item.posterUrl,
        plot: item.plot,
        runtime: item.runtime,
        director: item.director,
        awards: item.awards,
        boxOffice: item.boxOffice,
        imdbID: item.imdbID,
        imdbRating: item.imdbRating,
        metascore: item.metascore,
        rottenTomatoesRating: item.rottenTomatoesRating,
      );

      await mediaProvider.addMediaItem(updatedItem);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${item.title} added to ${_selectedType == 'watchlist' ? 'watchlist' : 'watched list'}'
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding item: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title),
      ),
      body: FutureBuilder<MediaItem?>(
        future: _detailedItem,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final item = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'poster-${item.imdbID}', // Hero tag
                  child: Center(
                    child: item.posterUrl != null
                        ? CachedNetworkImage(
                      imageUrl: item.posterUrl!,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                      height: 300,
                    )
                        : const Icon(Icons.movie, size: 100),
                  ),
                ),
                const SizedBox(height: 16),
                Text(item.title, style: theme.textTheme.headlineMedium),
                _buildInfoRow('Year', item.year),
                _buildInfoRow('Type', item.type),

                const Divider(thickness: 1, height: 20),

                _buildInfoRow('Runtime', item.runtime),
                _buildInfoRow('Director', item.director),
                _buildInfoRow('Awards', item.awards),

                const Divider(thickness: 1, height: 20),

                _buildInfoRow('Box Office', item.boxOffice),
                _buildInfoRow('IMDb Rating', item.imdbRating),
                _buildInfoRow('Metascore', item.metascore),
                _buildInfoRow('Rotten Tomatoes', item.rottenTomatoesRating),

                const Divider(thickness: 1, height: 20),

                if (item.plot != null) ...[
                  Text('Plot:', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(item.plot!),
                  const SizedBox(height: 24),
                ],

                _buildRadioButtons(),

                const SizedBox(height: 16),

                Center(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isLoading ? null : () => _addToList(context, item),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Text(_selectedType == 'watchlist' ? 'Add to Watchlist' : 'Add to Watched'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}