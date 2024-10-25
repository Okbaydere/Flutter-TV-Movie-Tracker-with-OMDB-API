class MediaItem {
  final int? id;
  final String title;
  final String type;
  final String? originalType; // Added to track original type for watchlist items
  final int year;
  final double? rating;
  final String? notes;
  final String? posterUrl;
  final String? plot;
  final String? runtime;
  final String? director;
  final String? awards;
  final String? boxOffice;
  final String? imdbID;
  final String? imdbRating;
  final String? metascore;
  final String? rottenTomatoesRating;
  final double? userRating;

  MediaItem({
    this.id,
    required this.title,
    required this.type,
    this.originalType,
    required this.year,
    this.rating,
    this.notes,
    this.posterUrl,
    this.plot,
    this.runtime,
    this.director,
    this.awards,
    this.boxOffice,
    this.imdbID,
    this.imdbRating,
    this.metascore,
    this.rottenTomatoesRating,
    this.userRating,
  });

  MediaItem copyWith({
    int? id,
    String? title,
    String? type,
    String? originalType,
    int? year,
    double? rating,
    String? notes,
    String? posterUrl,
    String? plot,
    String? runtime,
    String? director,
    String? awards,
    String? boxOffice,
    String? imdbID,
    String? imdbRating,
    String? metascore,
    String? rottenTomatoesRating,
    double? userRating,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      originalType: originalType ?? this.originalType,
      year: year ?? this.year,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      posterUrl: posterUrl ?? this.posterUrl,
      plot: plot ?? this.plot,
      runtime: runtime ?? this.runtime,
      director: director ?? this.director,
      awards: awards ?? this.awards,
      boxOffice: boxOffice ?? this.boxOffice,
      imdbID: imdbID ?? this.imdbID,
      imdbRating: imdbRating ?? this.imdbRating,
      metascore: metascore ?? this.metascore,
      rottenTomatoesRating: rottenTomatoesRating ?? this.rottenTomatoesRating,
      userRating: userRating ?? this.userRating,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'originalType': originalType,
      'year': year,
      'rating': rating,
      'notes': notes,
      'posterUrl': posterUrl,
      'plot': plot,
      'runtime': runtime,
      'director': director,
      'awards': awards,
      'boxOffice': boxOffice,
      'imdbID': imdbID,
      'imdbRating': imdbRating,
      'metascore': metascore,
      'rottenTomatoesRating': rottenTomatoesRating,
      'userRating': userRating,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'],
      title: map['title'],
      type: map['type'],
      originalType: map['originalType'],
      year: map['year'],
      rating: map['rating'],
      notes: map['notes'],
      posterUrl: map['posterUrl'],
      plot: map['plot'],
      runtime: map['runtime'],
      director: map['director'],
      awards: map['awards'],
      boxOffice: map['boxOffice'],
      imdbID: map['imdbID'],
      imdbRating: map['imdbRating'],
      metascore: map['metascore'],
      rottenTomatoesRating: map['rottenTomatoesRating'],
      userRating: map['userRating'],
    );
  }
}