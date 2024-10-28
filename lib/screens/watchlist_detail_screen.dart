import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_tracker/models/media_item.dart';
import 'package:media_tracker/providers/media_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WatchlistDetailScreen extends StatefulWidget {
  final MediaItem item;

  const WatchlistDetailScreen({super.key, required this.item});

  @override
  State<WatchlistDetailScreen> createState() => _WatchlistDetailScreenState();
}

class _WatchlistDetailScreenState extends State<WatchlistDetailScreen> {
  late TextEditingController _notesController;
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.item.notes);
    _notesController.addListener(() {
      setState(() => _hasUnsavedChanges = true);
    });
  }

  Widget _buildInfoRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
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

  Future<void> _moveToWatched() async {
    final targetType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Watched'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.item.originalType == 'movie')
              ListTile(
                leading: const Icon(Icons.movie),
                title: const Text('Movies'),
                onTap: () => Navigator.pop(context, 'movie'),
              ),
            if (widget.item.originalType == 'series')
              ListTile(
                leading: const Icon(Icons.tv),
                title: const Text('TV Shows'),
                onTap: () => Navigator.pop(context, 'series'),
              ),
          ],
        ),
      ),
    );

    if (targetType == null) return;

    setState(() => _isLoading = true);
    try {
      final mediaProvider = context.read<MediaProvider>();
      final watchedItem = widget.item.copyWith(
        type: targetType,
        originalType: null,
        notes: _notesController.text,
      );

      await mediaProvider.deleteMediaItem(widget.item.id!, 'watchlist');
      await mediaProvider.addMediaItem(watchedItem);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved to ${targetType == 'movie' ? 'movies' : 'TV shows'} list'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final updatedItem = widget.item.copyWith(
        notes: _notesController.text,
      );

      await context.read<MediaProvider>().updateMediaItem(updatedItem);
      setState(() => _hasUnsavedChanges = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to remove this item from your watchlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await context.read<MediaProvider>()
          .deleteMediaItem(widget.item.id!, 'watchlist');
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item: $e')),
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

    return PopScope<void>(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        final save = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save Changes?'),
            content: const Text('You have unsaved changes. Would you like to save them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Discard'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
        );

        if (save == true) {
          await _saveChanges();
        }

        if (mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.item.title),
          actions: [
            if (_hasUnsavedChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveChanges,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.item.posterUrl != null)
                Center(
                  child: Hero(
                    tag: 'watchlist_poster_${widget.item.id}',
                    child: CachedNetworkImage(
                      imageUrl: widget.item.posterUrl!,
                      height: 300,
                      placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(widget.item.title, style: theme.textTheme.headlineMedium),
              _buildInfoRow('Year', widget.item.year),
              _buildInfoRow('Type', widget.item.originalType),

              const Divider(thickness: 1, height: 20),

              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add your notes here...',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              _buildInfoRow('Runtime', widget.item.runtime),
              _buildInfoRow('Director', widget.item.director),
              _buildInfoRow('Awards', widget.item.awards),

              const Divider(thickness: 1, height: 20),

              _buildInfoRow('Box Office', widget.item.boxOffice),
              _buildInfoRow('IMDb Rating', widget.item.imdbRating),
              _buildInfoRow('Metascore', widget.item.metascore),
              _buildInfoRow('Rotten Tomatoes', widget.item.rottenTomatoesRating),

              const Divider(thickness: 1, height: 20),

              if (widget.item.plot != null) ...[
                Text('Plot:', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(widget.item.plot!),
              ],

              const SizedBox(height: 24),

              Center(
                child: Column(
                  children: [
                    FilledButton.icon(
                      onPressed: _moveToWatched,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Move to Watched'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _deleteItem,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove from Watchlist'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}