import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RandomSongsPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;

  const RandomSongsPage({
    super.key,
    required this.api,
    required this.playerService,
  });

  @override
  State<RandomSongsPage> createState() => _RandomSongsPageState();
}

class _RandomSongsPageState extends State<RandomSongsPage> {
  late Future<List<Map<String, dynamic>>> _songsFuture;
  String _totalDuration = "--:--";

  static const String _cacheKeyDate = 'random_songs_date';
  static const String _cacheKeySongs = 'random_songs_data';

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();
    final cachedDate = prefs.getString(_cacheKeyDate);
    final cachedSongsJson = prefs.getString(_cacheKeySongs);

    if (cachedDate == today && cachedSongsJson != null) {
      final cachedSongs = (jsonDecode(cachedSongsJson) as List)
          .cast<Map<String, dynamic>>();
      _songsFuture = Future.value(cachedSongs);
    } else {
      _songsFuture = widget.api.getRandomSongs(count: 50);
      _songsFuture.then((songs) async {
        await _cacheSongs(songs, today);
      });
    }

    _songsFuture.then((songs) {
      int totalSeconds = 0;
      for (var song in songs) {
        totalSeconds += int.tryParse(song['duration'] ?? '0') ?? 0;
      }
      setState(() {
        _totalDuration = _formatDuration(totalSeconds);
      });
    });
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _cacheSongs(
    List<Map<String, dynamic>> songs,
    String date,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKeyDate, date);
    await prefs.setString(_cacheKeySongs, jsonEncode(songs));
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _playSong(
    Map<String, dynamic> song,
    List<Map<String, dynamic>> playlist,
  ) {
    widget.playerService.playSong(
      song,
      sourceType: 'random',
      playlist: playlist,
    );
  }

  void _playAll(List<Map<String, dynamic>> songs) {
    if (songs.isNotEmpty) {
      widget.playerService.playSong(
        songs.first,
        sourceType: 'random',
        playlist: songs,
      );
    }
  }

  void _shuffleAndPlay(List<Map<String, dynamic>> songs) {
    if (songs.isNotEmpty) {
      final shuffled = List<Map<String, dynamic>>.from(songs);
      shuffled.shuffle();
      widget.playerService.playSong(
        shuffled.first,
        sourceType: 'random',
        playlist: shuffled,
      );
    }
  }

  Widget _buildPlaylistCoverGrid(List<Map<String, dynamic>> songs) {
    List<String> coverArts = [];
    for (var i = 0; i < songs.length && i < 4; i++) {
      if (songs[i]['coverArt'] != null) {
        coverArts.add(songs[i]['coverArt']);
      }
    }

    if (coverArts.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.shuffle,
          size: 100,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (coverArts.length == 1) {
      return CachedNetworkImage(
        imageUrl: widget.api.getCoverArtUrl(coverArts[0]),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    List<String> displayCovers = [];
    if (coverArts.length == 2) {
      displayCovers = [coverArts[0], coverArts[1], coverArts[1], coverArts[0]];
    } else if (coverArts.length == 3) {
      displayCovers = [coverArts[0], coverArts[1], coverArts[2], coverArts[0]];
    } else {
      displayCovers = coverArts;
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: widget.api.getCoverArtUrl(displayCovers[0]),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: widget.api.getCoverArtUrl(displayCovers[1]),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: widget.api.getCoverArtUrl(displayCovers[2]),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: widget.api.getCoverArtUrl(displayCovers[3]),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('随机歌曲')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _loadSongs();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final songs = snapshot.data ?? [];

          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text('暂无歌曲', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '随机歌曲',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${songs.length} 首歌曲 · $_totalDuration',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildPlaylistCoverGrid(songs),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _playAll(songs),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('播放全部'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _shuffleAndPlay(songs),
                              icon: const Icon(Icons.shuffle_rounded),
                              label: const Text('随机播放'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = songs[index];
                  return _buildSongItem(song, songs);
                }, childCount: songs.length),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSongItem(
    Map<String, dynamic> song,
    List<Map<String, dynamic>> playlist,
  ) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: song['coverArt'] != null
            ? CachedNetworkImage(
                imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              )
            : Container(
                width: 56,
                height: 56,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.music_note,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
      ),
      title: Text(
        song['title'] ?? '未知标题',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song['artist'] ?? '未知艺术家',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(int.tryParse(song['duration'] ?? '0') ?? 0),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () => _playSong(song, playlist),
            tooltip: '播放',
          ),
        ],
      ),
      onTap: () => _playSong(song, playlist),
    );
  }
}
