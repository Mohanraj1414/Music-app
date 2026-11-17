import 'package:Bloomee/core/models/exported.dart';

/// How IsaiFlow should discover new tracks after the current queue finishes.
enum RadioMode {
  related('Similar', 'Follow the artist and sound of this song'),
  balanced('Balanced', 'Mix related favourites with discoveries'),
  discover('Discover', 'Prioritise fresh artists and songs');

  const RadioMode(this.label, this.description);
  final String label;
  final String description;
}

enum ListeningMood {
  any('Any mood', ''),
  chill('Chill', 'chill relaxing'),
  romantic('Romantic', 'romantic love'),
  happy('Happy', 'happy feel good'),
  sad('Sad', 'sad emotional'),
  focus('Focus', 'calm focus'),
  workout('Workout', 'energetic workout');

  const ListeningMood(this.label, this.searchTerms);
  final String label;
  final String searchTerms;
}

enum RadioLanguage {
  automatic('Auto', ''),
  tamil('Tamil', 'Tamil'),
  english('English', 'English'),
  kannada('Kannada', 'Kannada'),
  hindi('Hindi', 'Hindi');

  const RadioLanguage(this.label, this.searchTerms);
  final String label;
  final String searchTerms;
}

class RecommendationSettings {
  final RadioMode mode;
  final ListeningMood mood;
  final RadioLanguage language;

  const RecommendationSettings({
    this.mode = RadioMode.balanced,
    this.mood = ListeningMood.any,
    this.language = RadioLanguage.automatic,
  });

  RecommendationSettings copyWith({
    RadioMode? mode,
    ListeningMood? mood,
    RadioLanguage? language,
  }) =>
      RecommendationSettings(
        mode: mode ?? this.mode,
        mood: mood ?? this.mood,
        language: language ?? this.language,
      );
}

/// Stable deduplication across different music-source plugin IDs.
/// Decorative title suffixes (official video, lyrics) are ignored, but
/// acoustic, live, instrumental, and remix versions remain distinct.
String recommendationTrackKey(Track track) {
  String tidy(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'\((?:official (?:music )?video|lyric video|lyrics|audio|visualizer)\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\[(?:official (?:music )?video|lyric video|lyrics|audio|visualizer)\]', caseSensitive: false), '')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();
  final artist = track.artists.isEmpty ? '' : tidy(track.artists.first.name);
  return '${tidy(track.title)}|$artist';
}

List<Track> chooseFreshTracks({
  required Iterable<Track> candidates,
  required Iterable<Track> queue,
  required Set<String> recentKeys,
  int limit = 8,
}) {
  if (limit <= 0) return const [];
  final usedIds = queue.map((track) => track.id).toSet();
  final usedKeys = queue.map(recommendationTrackKey).toSet()
    ..addAll(recentKeys);
  final result = <Track>[];
  final artistCounts = <String, int>{};
  final remaining = <Track>[];
  for (final track in candidates) {
    final key = recommendationTrackKey(track);
    if (track.id.isEmpty || key == '|' ||
        usedIds.contains(track.id) || usedKeys.contains(key)) continue;
    usedIds.add(track.id);
    usedKeys.add(key);
    remaining.add(track);
  }

  // Preserve source relevancy while spreading different artists. Never pick
  // the exact same title/artist pair twice, including from another provider.
  while (result.length < limit && remaining.isNotEmpty) {
    var selectedIndex = 0;
    var bestScore = -99999;
    for (var i = 0; i < remaining.length; i++) {
      final artist = remaining[i].artists.isNotEmpty
          ? remaining[i].artists.first.name.toLowerCase()
          : '';
      final score = 100 - i - (artistCounts[artist] ?? 0) * 35;
      if (score > bestScore) {
        bestScore = score;
        selectedIndex = i;
      }
    }
    final chosen = remaining.removeAt(selectedIndex);
    result.add(chosen);
    final artist = chosen.artists.isNotEmpty
        ? chosen.artists.first.name.toLowerCase()
        : '';
    artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
  }
  return result;
}

List<String> recommendationSearchQueries(
    RecommendationSettings settings, Track seed, int rotation) {
  final lang = settings.language.searchTerms;
  final mood = settings.mood.searchTerms;
  final artist = seed.artists.isEmpty ? '' : seed.artists.first.name.trim();
  final prefixes = [lang, mood].where((part) => part.isNotEmpty).join(' ');
  const variations = [
    'songs',
    'new songs',
    'hits',
    'indie songs',
    'popular music',
    'hidden gems',
  ];
  final varied = variations[rotation % variations.length];
  final query = [prefixes, varied].where((part) => part.isNotEmpty).join(' ');
  final relatedQuery = [artist, mood, 'songs']
      .where((part) => part.isNotEmpty).join(' ');
  switch (settings.mode) {
    case RadioMode.related:
      return [if (artist.isNotEmpty) relatedQuery, query];
    case RadioMode.discover:
      return [query, [prefixes, 'fresh music'].where((part) => part.isNotEmpty).join(' ')];
    case RadioMode.balanced:
      return [
        if (artist.isNotEmpty) relatedQuery,
        query,
      ];
  }
}
