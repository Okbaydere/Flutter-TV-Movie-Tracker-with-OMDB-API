import 'dart:io';

import 'package:csv/csv.dart';
import 'package:media_tracker/models/media_item.dart';
import 'package:media_tracker/services/database_helper.dart';

class CsvImportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> importCsvData(String filePath, String type) async {
    final input = await File(filePath).readAsString();
    final mediaItems = _parseCsv(input, type);
    await _importMediaItems(mediaItems);
  }

  List<MediaItem> _parseCsv(String csvData, String type) {
    final List<List<dynamic>> rows =
    const CsvToListConverter().convert(csvData);
    // Remove header row
    if (rows.isNotEmpty) {
      rows.removeAt(0);
    }
    return rows
        .map((row) => MediaItem(
      title: row[1].toString(), // Title is in the second column
      type: type,
      year: int.tryParse(row[5].toString()) ?? 0, // Year is in the sixth column (index 5)
      rating: double.tryParse(row[2].toString()),
      notes: row[3].toString(), // Watchlist in notes
      posterUrl: row[4].toString(),
    ))
        .toList();
  }

  Future<void> _importMediaItems(List<MediaItem> mediaItems) async {
    for (var item in mediaItems) {
      await _dbHelper.insertMediaItem(item);
    }
  }
}