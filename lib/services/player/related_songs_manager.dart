import 'dart:developer';
import 'package:Bloomee/core/models/exported.dart';
import 'package:Bloomee/plugins/utils/media_id.dart';
import 'package:Bloomee/core/constants/setting_keys.dart';
import 'package:Bloomee/services/db/db_provider.dart';
import 'package:Bloomee/services/db/dao/settings_dao.dart';
import 'package:Bloomee/services/player/player_engine.dart';
import 'package:Bloomee/services/plugin/plugin_service.dart';
import 'package:Bloomee/src/rust/api/plugin/commands.dart';
import 'package:rxdart/rxdart.dart';

class RelatedSongsManager {
  final BehaviorSubject<List<Track>> relatedSongs =
      BehaviorSubject<List<Track>>.seeded([]);
  final PluginService _pluginService;
  final Set<String> _fetchedTrackIds = <String>{};

  String? _referenceTrackId;
  String? _referenceLocalId;
  String? _pluginId;
  String? _nextPageToken;
  bool _isFetching = false;
  bool _isExhausted = false;
  int _lookupGeneration = 0;

  // Callbacks
  Function(List<Track> items, {bool atLast})? onAddQueueItems;

  RelatedSongsManager(this._pluginService);

  Future<void> checkForRelatedSongs({
    required Track currentMedia,
    required List<Track> queue,
    required int currentPlayingIdx,
    required LoopMode loopMode,
  }) async {
    log("Checking for related songs: ${queue.isNotEmpty && (queue.length - currentPlayingIdx) < 2}",
        name: "RelatedSongsManager");

    final autoPlay =
        await SettingsDAO(DBProvider.db).getSettingBool(SettingKeys.autoPlay);
    if (autoPlay != null && !autoPlay) return;

    final shouldQueueMore = queue.isNotEmpty &&
        (queue.length - currentPlayingIdx) < 2 &&
        loopMode != LoopMode.all;
    if (!shouldQueueMore) {
      return;
    }

    final parts = tryParseMediaId(currentMedia.id);
    if (parts == null) {
      return;
    }

    if (parts.pluginId == kLocalPluginId) {
      clearRelatedSongs();
      return;
    }

    _syncReferenceState(
      trackId: currentMedia.id,
      pluginId: parts.pluginId,
      localId: parts.localId,
    );

    if (relatedSongs.value.isEmpty) {
      await _fetchNextRadioPage();
    }

    await loadRelatedSongs(
        queue: queue, currentPlayingIdx: currentPlayingIdx, loopMode: loopMode);

    if (relatedSongs.value.isEmpty) {
      await _fetchNextRadioPage();
      await loadRelatedSongs(
        queue: queue,
        currentPlayingIdx: currentPlayingIdx,
        loopMode: loopMode,
      );
    }
  }

  Future<void> loadRelatedSongs({
    required List<Track> queue,
    required int currentPlayingIdx,
    required LoopMode loopMode,
  }) async {
    if (relatedSongs.value.isNotEmpty &&
        (queue.length - currentPlayingIdx) < 3 &&
        loopMode != LoopMode.all) {
      onAddQueueItems?.call(relatedSongs.value, atLast: true);
      relatedSongs.add([]);
    }
  }

  void clearRelatedSongs() {
    ++_lookupGeneration;
    relatedSongs.add([]);
    _fetchedTrackIds.clear();
    _referenceTrackId = null;
    _referenceLocalId = null;
    _pluginId = null;
    _nextPageToken = null;
    _isFetching = false;
    _isExhausted = false;
  }

  // FIX Bug-3: also reset _isExhausted when the same track is re-encountered
  // after looping, so radio pages can be fetched again.
  void _syncReferenceState({
    required String trackId,
    required String pluginId,
    required String localId,
  }) {
    if (_referenceTrackId == trackId && _pluginId == pluginId) {
      // Do not refetch an exhausted page every 15 seconds while listening.
      return;
    }

    ++_lookupGeneration;
    relatedSongs.add([]);
    _fetchedTrackIds.clear();
    _referenceTrackId = trackId;
    _referenceLocalId = localId;
    _pluginId = pluginId;
    _nextPageToken = null;
    _isFetching = false;
    _isExhausted = false;
  }

  Future<void> _fetchNextRadioPage() async {
    if (_isFetching ||
        _isExhausted ||
        _pluginId == null ||
        _referenceLocalId == null) {
      return;
    }

    _isFetching = true;
    final generation = _lookupGeneration;
    try {
      final response = await _pluginService.execute(
        pluginId: _pluginId!,
        request: PluginRequest.contentResolver(
          ContentResolverCommand.getRadioTracks(
            id: _referenceLocalId!,
            pageToken: _nextPageToken,
          ),
        ),
      );

      response.when(
        moreTracks: (pagedTracks) {
          // A previous track's slow radio response must never poison the new
          // track's queue after a skip or playlist replacement.
          if (generation != _lookupGeneration) return;
          final uniqueTracks = pagedTracks.items.where((track) {
            return _fetchedTrackIds.add(track.id);
          }).toList(growable: false);

          if (uniqueTracks.isNotEmpty) {
            relatedSongs.add([...relatedSongs.value, ...uniqueTracks]);
            log(
              'Buffered ${uniqueTracks.length} related songs',
              name: 'RelatedSongsManager',
            );
          }

          _nextPageToken = pagedTracks.nextPageToken;
          _isExhausted =
              pagedTracks.nextPageToken == null && uniqueTracks.isEmpty;
        },
        trackDetails: (_) {},
        albumDetails: (_) {},
        artistDetails: (_) {},
        playlistDetails: (_) {},
        streams: (_) {},
        search: (_) {},
        moreAlbums: (_) {},
        homeSections: (_) {},
        loadMoreItems: (_) {},
        charts: (_) {},
        chartDetails: (_) {},
        segments: (_) {},
        lyricsResult: (_) {},
        lyricsSearchResults: (_) {},
        lyricsById: (_, __) {},
        suggestions: (_) {},
        canHandle: (_) {},
        collectionInfo: (_) {},
        importTracks: (_) {},
        ack: () {},
      );
    } catch (e) {
      log('Failed to get related songs: $e', name: 'RelatedSongsManager');
    } finally {
      if (generation == _lookupGeneration) _isFetching = false;
    }
  }

  void dispose() {
    relatedSongs.close();
  }
}
