import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:Bloomee/core/models/exported.dart';
import 'package:Bloomee/core/constants/setting_keys.dart';
import 'package:Bloomee/plugins/utils/media_id.dart';
import 'package:Bloomee/services/db/db_provider.dart';
import 'package:Bloomee/services/db/dao/settings_dao.dart';
import 'package:Bloomee/services/player/player_engine.dart';
import 'package:Bloomee/services/player/recommendation_settings.dart';
import 'package:Bloomee/services/plugin/plugin_service.dart';
import 'package:Bloomee/src/rust/api/plugin/commands.dart';
import 'package:rxdart/rxdart.dart';

/// Dynamic, bounded autoplay recommendations. The provider determines what
/// songs exist: IsaiFlow only ranks available results, avoids recent repeats,
/// varies the search seed, and honours the selected mood/mode/language.
class RelatedSongsManager {
  final BehaviorSubject<List<Track>> relatedSongs =
      BehaviorSubject<List<Track>>.seeded(const []);
  final BehaviorSubject<RecommendationSettings> settings =
      BehaviorSubject<RecommendationSettings>.seeded(
          const RecommendationSettings());

  final PluginService _pluginService;
  final SettingsDAO _dao = SettingsDAO(DBProvider.db);
  final List<String> _recentKeys = [];
  final Set<String> _fetchedTrackIds = {};
  final Map<String, String?> _searchPages = {};
  final Set<String> _exhaustedSearches = {};
  final List<Track> _buffer = [];

  late final Future<void> _restored;
  Future<void> _historyWrite = Future<void>.value();
  int _configurationRevision = 0;
  int _lookupGeneration = 0;
  int _searchRotation = 0;
  String? _referenceTrackId;
  String? _localId;
  String? _pluginId;
  String? _nextRadioPage;
  bool _fetching = false;
  bool _radioExhausted = false;

  Function(List<Track> items, {bool atLast})? onAddQueueItems;

  RelatedSongsManager(this._pluginService) {
    _restored = _restoreSettings();
  }

  Future<void> _restoreSettings() async {
    try {
      final revision = _configurationRevision;
      final values = await Future.wait([
        _dao.getSettingStr(SettingKeys.radioMode),
        _dao.getSettingStr(SettingKeys.radioMood),
        _dao.getSettingStr(SettingKeys.radioLanguage),
        _dao.getSettingStr(SettingKeys.radioRecentKeys),
      ]);
      if (revision == _configurationRevision) {
        T parse<T extends Enum>(List<T> options, String? value, T fallback) {
          for (final item in options) {
            if (item.name == value) return item;
          }
          return fallback;
        }

        settings.add(RecommendationSettings(
          mode: parse(RadioMode.values, values[0], RadioMode.balanced),
          mood: parse(ListeningMood.values, values[1], ListeningMood.any),
          language: parse(RadioLanguage.values, values[2],
              RadioLanguage.automatic),
        ));
      }
      final raw = values[3];
      if (raw != null) {
        final parsed = jsonDecode(raw);
        if (parsed is List) {
          final restored = parsed.whereType<String>().toList();
          final newKeys = _recentKeys.toList();
          _recentKeys
            ..clear()
            ..addAll(restored.where((key) => !newKeys.contains(key)))
            ..addAll(newKeys);
          if (_recentKeys.length > 120) {
            _recentKeys.removeRange(0, _recentKeys.length - 120);
          }
        }
      }
    } catch (error) {
      log('Recommendation preferences could not be restored: $error',
          name: 'RelatedSongsManager');
    }
  }

  Future<void> setPreferences(RecommendationSettings preferences) async {
    ++_configurationRevision;
    settings.add(preferences);
    clearRelatedSongs();
    try {
      await Future.wait([
        _dao.putSettingStr(SettingKeys.radioMode, preferences.mode.name),
        _dao.putSettingStr(SettingKeys.radioMood, preferences.mood.name),
        _dao.putSettingStr(
            SettingKeys.radioLanguage, preferences.language.name),
      ]);
    } catch (error) {
      log('Could not save recommendation mode: $error',
          name: 'RelatedSongsManager');
    }
  }

  void recordPlayed(Track track) => _remember(track);

  void _remember(Track track) {
    final key = recommendationTrackKey(track);
    if (key == '|') return;
    _recentKeys.remove(key);
    _recentKeys.add(key);
    if (_recentKeys.length > 120) {
      _recentKeys.removeRange(0, _recentKeys.length - 120);
    }
    // Keep writes serial so an older asynchronous DB write cannot overwrite
    // a newer history snapshot when songs are skipped rapidly.
    final snapshot = jsonEncode(_recentKeys);
    _historyWrite = _historyWrite.catchError((Object _) {}).then((_) =>
        _dao.putSettingStr(SettingKeys.radioRecentKeys, snapshot))
      .catchError((Object error) {
        log('Could not persist recommendation history: $error',
            name: 'RelatedSongsManager');
      });
  }

  Future<void> checkForRelatedSongs({
    required Track currentMedia,
    required List<Track> queue,
    required int currentPlayingIdx,
    required LoopMode loopMode,
  }) async {
    await _restored;
    final autoPlay = await _dao.getSettingBool(SettingKeys.autoPlay);
    if (autoPlay == false ||
        loopMode == LoopMode.all ||
        queue.isEmpty ||
        currentPlayingIdx < 0 ||
        queue.length - currentPlayingIdx > 4) {
      return;
    }
    final parsed = tryParseMediaId(currentMedia.id);
    if (parsed == null || parsed.pluginId == kLocalPluginId) return;

    _syncReference(trackId: currentMedia.id,
        pluginId: parsed.pluginId, localId: parsed.localId);
    final generation = _lookupGeneration;
    if (_fetching) return;
    _fetching = true;
    try {
      final config = settings.value;
      // A mood/language can only be approximated by the provider's search;
      // raw radio recommendations do not contain verified mood labels.
      final specific = config.mood != ListeningMood.any ||
          config.language != RadioLanguage.automatic;
      final searchFirst = specific ||
          config.mode == RadioMode.discover ||
          (config.mode == RadioMode.balanced && _searchRotation.isEven);
      List<Track> select() => chooseFreshTracks(
            candidates: _buffer,
            queue: queue,
            recentKeys: _recentKeys.toSet(),
            limit: 7,
          );

      if (searchFirst) await _fetchSearch(currentMedia, generation);
      if (!specific && select().length < 4) {
        await _fetchRadio(generation);
      }
      if (select().length < 3) {
        await _fetchSearch(currentMedia, generation);
      }
      // Providers sometimes return a full page of tracks the user has
      // already heard. Continue paging rather than treating that page as
      // enough merely because it contained several results.
      if (!specific && select().length < 2 && !_radioExhausted) {
        await _fetchRadio(generation);
      }
      if (select().isEmpty) {
        await _fetchSearch(currentMedia, generation);
      }
      if (generation != _lookupGeneration) return;
      final selected = select();
      if (selected.isEmpty) {
        // Exhausted or repetitive results should not cause the same 10 songs
        // to be re-appended over and over.
        _buffer.clear();
        return;
      }

      final pickedIds = selected.map((track) => track.id).toSet();
      _buffer.removeWhere((track) => pickedIds.contains(track.id));
      for (final track in selected) {
        _remember(track);
      }
      onAddQueueItems?.call(selected, atLast: true);
      log('Autoplay added ${selected.length} unique tracks '
          '(mode: ${config.mode.name}, mood: ${config.mood.name})',
          name: 'RelatedSongsManager');
    } catch (error) {
      log('Recommendation fetch failed: $error',
          name: 'RelatedSongsManager');
    } finally {
      if (generation == _lookupGeneration) _fetching = false;
    }
  }

  void _syncReference({
    required String trackId,
    required String pluginId,
    required String localId,
  }) {
    if (_referenceTrackId == trackId && _pluginId == pluginId) return;
    ++_lookupGeneration;
    _referenceTrackId = trackId;
    _pluginId = pluginId;
    _localId = localId;
    _nextRadioPage = null;
    _radioExhausted = false;
    _buffer.clear();
    _fetchedTrackIds.clear();
    _searchPages.clear();
    _exhaustedSearches.clear();
    _fetching = false;
  }

  Future<void> _fetchRadio(int generation) async {
    if (_radioExhausted || _pluginId == null || _localId == null) return;
    final response = await _pluginService.execute(
      pluginId: _pluginId!,
      request: PluginRequest.contentResolver(
        ContentResolverCommand.getRadioTracks(
          id: _localId!, pageToken: _nextRadioPage),
      ),
    );
    response.when(
      moreTracks: (paged) {
        if (generation != _lookupGeneration) return;
        for (final track in paged.items) {
          if (_fetchedTrackIds.add(track.id)) _buffer.add(track);
        }
        _nextRadioPage = paged.nextPageToken;
        // The terminal radio page is terminal even when it contains songs.
        _radioExhausted = paged.nextPageToken == null ||
            paged.nextPageToken == '';
      },
      trackDetails: (_) {}, albumDetails: (_) {}, artistDetails: (_) {},
      playlistDetails: (_) {}, streams: (_) {}, search: (_) {},
      moreAlbums: (_) {}, homeSections: (_) {}, loadMoreItems: (_) {},
      charts: (_) {}, chartDetails: (_) {}, segments: (_) {},
      lyricsResult: (_) {}, lyricsSearchResults: (_) {}, lyricsById: (_, __) {},
      suggestions: (_) {}, canHandle: (_) {}, collectionInfo: (_) {},
      importTracks: (_) {}, ack: () {},
    );
  }

  Future<void> _fetchSearch(Track current, int generation) async {
    final queries = recommendationSearchQueries(
        settings.value, current, _searchRotation++);
    for (final query in queries) {
      if (generation != _lookupGeneration) return;
      if (_exhaustedSearches.contains(query)) continue;
      try {
        final response = await _pluginService.execute(
          pluginId: _pluginId!,
          request: PluginRequest.contentResolver(
            ContentResolverCommand.search(
              query: query,
              filter: ContentSearchFilter.track,
              pageToken: _searchPages[query],
            ),
          ),
        );
        response.when(
          search: (paged) {
            if (generation != _lookupGeneration) return;
            for (final item in paged.items) {
              item.when(
                track: (track) {
                  if (_fetchedTrackIds.add(track.id)) _buffer.add(track);
                },
                album: (_) {}, artist: (_) {}, playlist: (_) {},
              );
            }
            final next = paged.nextPageToken;
            if (next == null || next == '') {
              _exhaustedSearches.add(query);
            } else {
              _searchPages[query] = next;
            }
          },
          trackDetails: (_) {}, albumDetails: (_) {}, artistDetails: (_) {},
          playlistDetails: (_) {}, streams: (_) {}, moreTracks: (_) {},
          moreAlbums: (_) {}, homeSections: (_) {}, loadMoreItems: (_) {},
          charts: (_) {}, chartDetails: (_) {}, segments: (_) {},
          lyricsResult: (_) {}, lyricsSearchResults: (_) {},
          lyricsById: (_, __) {}, suggestions: (_) {}, canHandle: (_) {},
          collectionInfo: (_) {}, importTracks: (_) {}, ack: () {},
        );
      } catch (error) {
        log('Search suggestion failed for $query: $error',
            name: 'RelatedSongsManager');
      }
      // Track counts alone are misleading when a provider repeats its
      // first results. Leave room for another query when this page is stale.
      if (_buffer.length >= 20) return;
    }
  }

  void clearRelatedSongs() {
    ++_lookupGeneration;
    relatedSongs.add(const []);
    _buffer.clear();
    _fetchedTrackIds.clear();
    _searchPages.clear();
    _exhaustedSearches.clear();
    _referenceTrackId = null;
    _pluginId = null;
    _localId = null;
    _nextRadioPage = null;
    _fetching = false;
    _radioExhausted = false;
  }

  Future<void> loadRelatedSongs({
    required List<Track> queue,
    required int currentPlayingIdx,
    required LoopMode loopMode,
  }) async {
    // Kept for old caller compatibility: recommendations are directly queued
    // in checkForRelatedSongs to prevent duplicate submissions.
  }

  void dispose() {
    relatedSongs.close();
    settings.close();
  }
}
