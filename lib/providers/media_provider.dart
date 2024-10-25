import 'package:flutter/foundation.dart';
import 'package:media_tracker/models/media_item.dart';
import 'package:media_tracker/services/database_helper.dart';
import 'package:media_tracker/services/omdb_service.dart';

class MediaProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final OmdbService _omdbService = OmdbService();

  List<MediaItem> _movies = [];
  List<MediaItem> _tvShows = [];
  List<MediaItem> _anime = [];
  List<MediaItem> _watchlist = [];

  List<MediaItem> get movies => _movies;
  List<MediaItem> get tvShows => _tvShows;
  List<MediaItem> get anime => _anime;
  List<MediaItem> get watchlist => _watchlist;

  Future<void> refreshMedia(String type) async {
    switch (type) {
      case 'movie':
        _movies = await _dbHelper.getMediaItems(type);
        break;
      case 'series':
        _tvShows = await _dbHelper.getMediaItems(type);
        break;
      case 'anime':
        _anime = await _dbHelper.getMediaItems(type);
        break;
      case 'watchlist':
        _watchlist = await _dbHelper.getMediaItems(type);
        break;
    }
    notifyListeners();
  }

  Future<void> loadAllMedia() async {
    if (DatabaseHelper.instance.isDatabaseInitialized) {
      _movies = await _dbHelper.getMediaItems('movie');
      _tvShows = await _dbHelper.getMediaItems('series');
      _anime = await _dbHelper.getMediaItems('anime');
      _watchlist = await _dbHelper.getMediaItems('watchlist');
      notifyListeners();
    }
  }

  Future<MediaItem> addMediaItem(MediaItem item) async {
    try {
      final details = await _omdbService.getMediaDetails(item.imdbID ?? '');
      if (details != null) {
        item = item.copyWith(
          posterUrl: details.posterUrl,
          plot: details.plot,
          runtime: details.runtime,
          director: details.director,
          awards: details.awards,
          boxOffice: details.boxOffice,
          imdbRating: details.imdbRating,
          metascore: details.metascore,
          rottenTomatoesRating: details.rottenTomatoesRating,
          userRating: item.userRating ?? 0.0,
        );
      }
      final id = await _dbHelper.insertMediaItem(item);
      item = item.copyWith(id: id); // Update the item with the new ID
      await refreshMedia(item.type);
      return item;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMediaItem(MediaItem item) async {
    if (item.id == null) {
      throw Exception('Cannot update item without id');
    }
    await _dbHelper.updateMediaItem(item);
    await refreshMedia(item.type);
  }

  Future<void> deleteMediaItem(int id, String type) async {
    await _dbHelper.deleteMediaItem(id);
    await refreshMedia(type);
  }

  Future<List<MediaItem>> searchMedia(String query) async {
    return await _omdbService.searchMedia(query);
  }

  Future<MediaItem?> getMediaDetails(String imdbId) async {
    return await _omdbService.getMediaDetails(imdbId);
  }
}