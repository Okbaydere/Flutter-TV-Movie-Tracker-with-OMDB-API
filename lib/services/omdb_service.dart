import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:media_tracker/models/media_item.dart';

class OmdbService {
  final String apiKey = 'YOUR OMDB API KEY HERE';
  final String baseUrl = 'http://www.omdbapi.com/';

  Future<List<MediaItem>> searchMedia(String query) async {
    if (query.isEmpty) {
      throw ArgumentError('Search query cannot be empty');
    }

    try {
      final response = await http.get(
          Uri.parse('$baseUrl?apikey=$apiKey&s=${Uri.encodeComponent(query)}')
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Response'] == 'True' && data.containsKey('Search')) {
          return (data['Search'] as List).map((item) => MediaItem(
            title: item['Title'] ?? '',
            type: item['Type'] ?? '',
            year: int.tryParse(item['Year']?.substring(0, 4) ?? '0') ?? 0,
            posterUrl: item['Poster'] != 'N/A' ? item['Poster'] : null,
            imdbID: item['imdbID'] ?? '',
          )).toList();
        } else {
          throw Exception(data['Error'] ?? 'Unknown API error');
        }
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to search media: $e');
    }
  }

  Future<MediaItem?> getMediaDetails(String imdbId) async {
    if (imdbId.isEmpty) {
      throw ArgumentError('IMDB ID cannot be empty');
    }

    try {
      final response = await http.get(
          Uri.parse('$baseUrl?apikey=$apiKey&i=$imdbId&plot=full')
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Response'] == 'True') {
          return MediaItem(
            title: data['Title'] ?? '',
            type: data['Type'] ?? '',
            year: int.tryParse(data['Year']?.substring(0, 4) ?? '0') ?? 0,
            rating: double.tryParse(data['imdbRating'] ?? '0.0'),
            posterUrl: data['Poster'] != 'N/A' ? data['Poster'] : null,
            plot: data['Plot'] ?? '',
            runtime: data['Runtime'] ?? '',
            director: data['Director'] ?? '',
            awards: data['Awards'] ?? '',
            boxOffice: data['BoxOffice'] ?? '',
            imdbID: data['imdbID'] ?? '',
            imdbRating: data['imdbRating'] ?? '',
            metascore: data['Metascore'] ?? '',
            rottenTomatoesRating: _extractRottenTomatoesRating(data['Ratings']),
          );
        } else {
          throw Exception(data['Error'] ?? 'Unknown API error');
        }
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to get media details: $e');
    }
  }

  String _extractRottenTomatoesRating(List<dynamic>? ratings) {
    if (ratings == null) return 'N/A';
    final rottenTomatoesRating = ratings.firstWhere(
          (rating) => rating['Source'] == 'Rotten Tomatoes',
      orElse: () => {'Value': 'N/A'},
    );
    return rottenTomatoesRating['Value'];
  }
}
