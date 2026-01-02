import 'package:flutter/material.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SimilarSongsPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;

  const SimilarSongsPage({
    super.key,
    required this.api,
    required this.playerService,
  });

  @override
  State<SimilarSongsPage> createState() => _SimilarSongsPageState();
}

class _SimilarSongsPageState extends State<SimilarSongsPage> {
  late Future<List<Map<String, dynamic>>> _songsFuture;
  String _totalDuration = "--:--";
  Map<String, dynamic>? _baseSong;
  String _recommendationType = "基于播放历史";

  @override
  void initState() {
    super.initState();
    _songsFuture = _loadSongs();
  }

  Future<List<Map<String, dynamic>>> _loadSongs() async {
    String songId;
    String? artistName;
    int? year;

    if (widget.playerService.currentSong != null) {
      songId = widget.playerService.currentSong!['id']!;
      artistName = widget.playerService.currentSong!['artist'];
      _baseSong = widget.playerService.currentSong;
      print('🎵 使用当前播放歌曲: ${widget.playerService.currentSong!}');
      print('🎵 artistName: $artistName');
    } else {
      final randomSongs = await widget.api.getRandomSongs(count: 1);
      if (randomSongs.isNotEmpty) {
        songId = randomSongs[0]['id']!;
        artistName = randomSongs[0]['artist'];
        _baseSong = randomSongs[0];
        print('🎵 使用随机歌曲: ${randomSongs[0]}');
        print('🎵 artistName: $artistName');
      } else {
        return [];
      }
    }

    List<Map<String, dynamic>> songs = [];
    List<String> recommendationTypes = [];

    try {
      const int artistSongsCount = 10;
      const int yearRangeSongsCount = 10;
      const int totalTargetCount = 20;

      if (artistName != null) {
        print('🎵 获取同艺术家歌曲: $artistName');
        final artistSongs = await widget.api.getSongsByArtistName(artistName);
        print('🎵 艺术家歌曲总数: ${artistSongs.length}');
        final filteredArtistSongs = artistSongs
            .where((song) => song['id'] != songId)
            .take(artistSongsCount)
            .toList();
        print('🎵 过滤后艺术家歌曲数: ${filteredArtistSongs.length}');

        if (filteredArtistSongs.isNotEmpty) {
          songs.addAll(filteredArtistSongs);
          recommendationTypes.add('同艺术家的歌曲');
        }
      }

      if (songs.length < totalTargetCount) {
        int currentYear = DateTime.now().year;
        int startYear = currentYear - 3;
        print('🎵 获取年份范围内歌曲: $startYear - $currentYear');

        final yearSongs = await widget.api.getSongsByYearRange(
          startYear,
          currentYear,
          count: yearRangeSongsCount,
          excludeArtist: artistName,
        );
        print('🎵 年份范围内歌曲数: ${yearSongs.length}');

        final filteredYearSongs = yearSongs
            .where(
              (song) =>
                  song['id'] != songId &&
                  !songs.any((s) => s['id'] == song['id']),
            )
            .take(yearRangeSongsCount)
            .toList();
        print('🎵 过滤后年份范围歌曲数: ${filteredYearSongs.length}');

        if (filteredYearSongs.isNotEmpty) {
          songs.addAll(filteredYearSongs);
          recommendationTypes.add('同年份推荐');
        }
      }

      if (songs.length < totalTargetCount) {
        int remainingCount = totalTargetCount - songs.length;
        print('🎵 获取随机歌曲补充: $remainingCount 首');
        final randomSongs = await widget.api.getRandomSongs(
          count: remainingCount,
        );
        print('🎵 随机歌曲数量: ${randomSongs.length}');

        final filteredRandomSongs = randomSongs
            .where(
              (song) =>
                  song['id'] != songId &&
                  !songs.any((s) => s['id'] == song['id']),
            )
            .toList();
        print('🎵 过滤后随机歌曲数: ${filteredRandomSongs.length}');

        if (filteredRandomSongs.isNotEmpty) {
          songs.addAll(filteredRandomSongs);
          if (!recommendationTypes.contains('随机推荐')) {
            recommendationTypes.add('随机推荐');
          }
        }
      }

      setState(() {
        _recommendationType = recommendationTypes.join(' · ');
      });

      songs.shuffle();
      print('🎵 最终推荐歌曲数量: ${songs.length}');
    } catch (e) {
      print('获取推荐歌曲失败: $e');
      try {
        final randomSongs = await widget.api.getRandomSongs(count: 20);
        songs = randomSongs;
        setState(() {
          _recommendationType = "随机推荐";
        });
      } catch (e2) {
        print('获取随机歌曲失败: $e2');
      }
    }

    int totalSeconds = 0;
    for (var song in songs) {
      totalSeconds += int.tryParse(song['duration'] ?? '0') ?? 0;
    }
    setState(() {
      _totalDuration = _formatDuration(totalSeconds);
    });

    return songs;
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
      sourceType: 'similar',
      playlist: playlist,
    );
  }

  void _playAll(List<Map<String, dynamic>> songs) {
    if (songs.isNotEmpty) {
      widget.playerService.playSong(
        songs.first,
        sourceType: 'similar',
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
        sourceType: 'similar',
        playlist: shuffled,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('推荐歌曲')),
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
                  Text('暂无推荐歌曲', style: Theme.of(context).textTheme.titleLarge),
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
                                  '推荐歌曲',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_recommendationType · ${songs.length} 首歌曲 · $_totalDuration',
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
                              child:
                                  _baseSong != null &&
                                      _baseSong!['coverArt'] != null
                                  ? CachedNetworkImage(
                                      imageUrl: widget.api.getCoverArtUrl(
                                        _baseSong!['coverArt'],
                                      ),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : Icon(
                                      Icons.recommend,
                                      size: 64,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_baseSong != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '基于 "${_baseSong!['title']}" - ${_baseSong!['artist']}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
