import 'package:Bloomee/services/player/recommendation_settings.dart';
import 'package:Bloomee/src/rust/api/plugin/models.dart';
import 'package:flutter_test/flutter_test.dart';

Track song(String id, String title, String artist) => Track(
      id: id,
      title: title,
      artists: [ArtistSummary(id: 'artist-$artist', name: artist)],
      thumbnail: const Artwork(url: '', layout: ImageLayout.square),
      isExplicit: false,
    );

void main() {
  group('IsaiFlow fresh autoplay', () {
    test('rejects repeated songs from multiple providers', () {
      final existing = song('pluginA:1', 'Moon Song', 'Singer A');
      final results = chooseFreshTracks(
        candidates: [
          song('pluginB:7', 'Moon Song (Official Video)', 'Singer A'),
          song('pluginB:8', 'Moon Song', 'Singer B'),
          song('pluginA:3', 'Fresh Track', 'Singer C'),
        ],
        queue: [existing],
        recentKeys: {},
      );
      expect(results.map((t) => t.title).toList(),
          ['Moon Song', 'Fresh Track']);
      expect(results.first.artists.first.name, 'Singer B');
    });

    test('excludes previously heard songs after queue resets', () {
      final past = song('plugin:3', 'Old Favourite', 'Singer A');
      final results = chooseFreshTracks(
        candidates: [past, song('plugin:4', 'New Find', 'Singer B')],
        queue: [],
        recentKeys: {recommendationTrackKey(past)},
      );
      expect(results.map((t) => t.title), ['New Find']);
    });

    test('spreads different artists when provider returns repeated artists', () {
      final results = chooseFreshTracks(
        candidates: [
          song('a1', 'One', 'A'),
          song('a2', 'Two', 'A'),
          song('a3', 'Three', 'A'),
          song('b1', 'Four', 'B'),
        ],
        queue: [],
        recentKeys: {},
        limit: 3,
      );
      expect(results.first.title, 'One');
      expect(results[1].artists.first.name, 'B');
    });

    test('never manufactures duplicates if catalog is exhausted', () {
      final s = song('p:1', 'Played Already', 'Singer');
      final results = chooseFreshTracks(
          candidates: [s, s], queue: [s], recentKeys: {});
      expect(results, isEmpty);
    });

    test('mood and language change search query', () {
      final seed = song('p:seed', 'Example Song', 'Example Artist');
      const config = RecommendationSettings(
        mode: RadioMode.discover,
        mood: ListeningMood.chill,
        language: RadioLanguage.tamil,
      );
      final queries = recommendationSearchQueries(config, seed, 2);
      expect(queries.first, contains('Tamil'));
      expect(queries.first, contains('chill'));
      expect(queries.first, contains('hits'));
    });

    test('discover mode rotates searches instead of one fixed search', () {
      final seed = song('p:seed', 'Example Song', 'Example Artist');
      const config = RecommendationSettings(mode: RadioMode.discover);
      expect(
        recommendationSearchQueries(config, seed, 0).first,
        isNot(recommendationSearchQueries(config, seed, 1).first),
      );
    });
  });
}
