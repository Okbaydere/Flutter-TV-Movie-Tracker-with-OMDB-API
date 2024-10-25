import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_tracker/screens/search_screen.dart';
import 'package:media_tracker/screens/watchlist_screen.dart';
import 'package:media_tracker/services/csv_import_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../services/database_helper.dart';
import 'media_list_screen.dart';
import '../providers/media_provider.dart';

enum MediaType {
  movie('movie'),
  series('series'),
  anime('anime'),
  watchlist('watchlist');

  final String value;
  const MediaType(this.value);

  String get displayName => name.capitalize();
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasStoragePermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAndLoadDatabase();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    bool granted = await _requestPermissions();
    setState(() {
      _hasStoragePermission = granted;
    });
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
    ].request();

    bool hasStoragePermission = statuses[Permission.storage]?.isGranted ?? false;
    bool hasPhotosPermission = statuses[Permission.photos]?.isGranted ?? false;
    bool hasVideosPermission = statuses[Permission.videos]?.isGranted ?? false;

    return hasStoragePermission || hasPhotosPermission || hasVideosPermission;
  }

  Future<void> _initAndLoadDatabase() async {
    setState(() {
      _isLoading = true;
    });
    await DatabaseHelper.instance.database;
    await Provider.of<MediaProvider>(context, listen: false).loadAllMedia();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _importCsvData(MediaType type) async {
    try {
      if (!_hasStoragePermission) {
        bool granted = await _requestPermissions();
        if (!granted) {
          if (mounted) {
            _showPermissionError();
          }
          return;
        }
        setState(() {
          _hasStoragePermission = true;
        });
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          final csvImportService = CsvImportService();
          await csvImportService.importCsvData(file.path!, type.value);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('CSV data imported for ${type.displayName} successfully!')),
            );
            await Provider.of<MediaProvider>(context, listen: false).refreshMedia(type.value);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import CSV: $e')),
        );
      }
    }
  }

  void _showPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Storage permission is required. Please grant permission in Settings.'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(MediaProvider mediaProvider) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Library Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Movies', mediaProvider.movies.length),
            _buildStatRow('TV Shows', mediaProvider.tvShows.length),
            _buildStatRow('Anime', mediaProvider.anime.length),
            _buildStatRow('Watchlist', mediaProvider.watchlist.length),
            const Divider(),
            _buildStatRow(
              'Total Items',
              mediaProvider.movies.length +
                  mediaProvider.tvShows.length +
                  mediaProvider.anime.length +
                  mediaProvider.watchlist.length,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Media Tracker'),
            actions: [
              IconButton(
                onPressed: () => _showImportDialog(context),
                icon: const Icon(Icons.file_upload),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading media data...'),
              ],
            ),
          )
              : SingleChildScrollView(
            child: Column(
              children: [
                _buildStatisticsCard(mediaProvider),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildCategoryCard(context, 'Movies', mediaProvider.movies.length, MediaType.movie),
                      _buildCategoryCard(context, 'TV Shows', mediaProvider.tvShows.length, MediaType.series),
                      _buildCategoryCard(context, 'Anime', mediaProvider.anime.length, MediaType.anime),
                      _buildCategoryCard(context, 'Watchlist', mediaProvider.watchlist.length, MediaType.watchlist),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, String categoryName, int count, MediaType type) {
    IconData icon;
    switch (type) {
      case MediaType.movie:
        icon = Icons.movie;
        break;
      case MediaType.series:
        icon = Icons.tv;
        break;
      case MediaType.anime:
        icon = Icons.animation;
        break;
      default:
        icon = Icons.list;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => type == MediaType.watchlist
                  ? const WatchlistScreen()
                  : MediaListScreen(type: type),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 6),
              Text(
                categoryName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$count items',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import CSV'),
          content: const Text('Select a CSV file to import.'),
          actions: [
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () {
                    _importCsvData(MediaType.movie);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Movies'),
                ),
                TextButton(
                  onPressed: () {
                    _importCsvData(MediaType.series);
                    Navigator.of(context).pop();
                  },
                  child: const Text('TV Shows'),
                ),
                TextButton(
                  onPressed: () {
                    _importCsvData(MediaType.anime);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Anime'),
                ),
                TextButton(
                  onPressed: () {
                    _importCsvData(MediaType.watchlist);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Watchlist'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}