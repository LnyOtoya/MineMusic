import 'package:flutter/material.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import '../utils/app_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'detail_page.dart' as dp;

class ArtistDetailPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;
  final Map<String, dynamic> artist;

  const ArtistDetailPage({
    super.key,
    required this.api,
    required this.playerService,
    required this.artist,
  });

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  late Future<List<Map<String, dynamic>>> _albumsFuture;
  late Future<List<Map<String, dynamic>>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _albumsFuture = widget.api.getAlbumsByArtist(widget.artist['id']);
    _songsFuture = widget.api.getSongsByArtist(widget.artist['id']);
  }

  void _playSong(
    Map<String, dynamic> song,
    List<Map<String, dynamic>> playlist,
  ) {
    widget.playerService.playSong(
      song,
      sourceType: 'artist',
      playlist: playlist,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '艺术家',
                          style: AppFonts.getTextStyle(
                            text: '艺术家',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.8,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: widget.artist['coverArt'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: widget.api.getCoverArtUrl(
                                          widget.artist['coverArt'],
                                        ),
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.artist['name'] ?? '未知艺术家',
                                    style: AppFonts.getTextStyle(
                                      text: widget.artist['name'] ?? '未知艺术家',
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '暂无艺术家介绍信息',
                                    style: AppFonts.getTextStyle(
                                      text: '暂无艺术家介绍信息',
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          '热门歌曲',
                          style: AppFonts.getTextStyle(
                            text: '热门歌曲',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _songsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text('加载失败: ${snapshot.error}'),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _songsFuture = widget.api.getSongsByArtist(
                                        widget.artist['id'],
                                      );
                                    });
                                  },
                                  child: const Text('重试'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final songs = snapshot.data ?? [];
                      
                      // 按专辑分组，确保显示的歌曲来自不同专辑
                      final Map<String, List<Map<String, dynamic>>> songsByAlbum = {};
                      for (var song in songs) {
                        final album = song['album'] as String?;
                        if (album != null) {
                          if (!songsByAlbum.containsKey(album)) {
                            songsByAlbum[album] = [];
                          }
                          songsByAlbum[album]!.add(song);
                        }
                      }
                      
                      // 从每个专辑中取第一首歌，最多取3首
                      final displaySongs = songsByAlbum.values
                          .take(3)
                          .expand((albumSongs) => albumSongs.take(1))
                          .toList();

                      return Column(
                        children: [
                          ...displaySongs.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            final song = entry.value;
                            final coverArtUrl = song['coverArt'] != null 
                                ? widget.api.getCoverArtUrl(song['coverArt']) 
                                : null;
                            final currentSong = widget.playerService.currentSong;
                            final isCurrentSong = currentSong != null && 
                                currentSong['id'] == song['id'];
                            final isPlaying = isCurrentSong && widget.playerService.isPlaying;
                            
                            return _buildSongItem(index, song, coverArtUrl, isCurrentSong, isPlaying, songs);
                          }).toList(),
                          if (songs.length > 3)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => _AllSongsPage(
                                        api: widget.api,
                                        playerService: widget.playerService,
                                        artist: widget.artist,
                                        songs: songs,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '查看全部 ${songs.length} 首歌曲',
                                      style: AppFonts.getTextStyle(
                                        text: '查看全部 ${songs.length} 首歌曲',
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          '专辑',
                          style: AppFonts.getTextStyle(
                            text: '专辑',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _albumsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text('加载失败: ${snapshot.error}'),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _albumsFuture = widget.api.getAlbumsByArtist(
                                        widget.artist['id'],
                                      );
                                    });
                                  },
                                  child: const Text('重试'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final albums = snapshot.data ?? [];

                      if (albums.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              '该艺术家暂无专辑',
                              style: AppFonts.getTextStyle(
                                text: '该艺术家暂无专辑',
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          _buildAlbumGrid(albums),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _AllAlbumsPage(
                                      api: widget.api,
                                      playerService: widget.playerService,
                                      artist: widget.artist,
                                      albums: albums,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '查看全部 ${albums.length} 张专辑',
                                    style: AppFonts.getTextStyle(
                                      text: '查看全部 ${albums.length} 张专辑',
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongItem(
    int index,
    Map<String, dynamic> song,
    String? coverArtUrl,
    bool isCurrentSong,
    bool isPlaying,
    List<Map<String, dynamic>> playlist,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _playSong(song, playlist),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isCurrentSong 
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isCurrentSong
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '$index',
                    style: AppFonts.getTextStyle(
                      text: '$index',
                      fontSize: 16,
                      color: isCurrentSong
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: coverArtUrl != null
                        ? CachedNetworkImage(
                            imageUrl: coverArtUrl,
                            fit: BoxFit.cover,
                            width: 48,
                            height: 48,
                            placeholder: (context, url) => Icon(
                              Icons.music_note_rounded,
                              size: 24,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.4),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.music_note_rounded,
                              size: 24,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.4),
                            ),
                          )
                        : Icon(
                            Icons.music_note_rounded,
                            size: 24,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.4),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song['title'] ?? '未知歌曲',
                        style: AppFonts.getTextStyle(
                          text: song['title'] ?? '未知歌曲',
                          fontSize: 16,
                          color: isCurrentSong
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song['album'] ?? '未知专辑',
                        style: AppFonts.getTextStyle(
                          text: song['album'] ?? '未知专辑',
                          fontSize: 14,
                          color: isCurrentSong
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDuration(song['duration']),
                  style: AppFonts.getTextStyle(
                    text: _formatDuration(song['duration']),
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumGrid(List<Map<String, dynamic>> albums) {
    final displayAlbums = albums.take(4).toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: displayAlbums.map((album) => _buildAlbumCard(album)).toList(),
      ),
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openAlbumDetail(context, album),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: album['coverArt'] != null
                      ? CachedNetworkImage(
                          imageUrl: widget.api.getCoverArtUrl(album['coverArt']),
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          placeholder: (context, url) => Icon(
                            Icons.album,
                            size: 32,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.album,
                            size: 32,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Icon(
                          Icons.album,
                          size: 32,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      album['name'] ?? '未知专辑',
                      style: AppFonts.getTextStyle(
                        text: album['name'] ?? '未知专辑',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${album['songCount'] ?? 0} 首歌曲',
                      style: AppFonts.getTextStyle(
                        text: '${album['songCount'] ?? 0} 首歌曲',
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(dynamic duration) {
    if (duration == null) return '--:--';
    int seconds;
    if (duration is String) {
      seconds = int.tryParse(duration) ?? 0;
    } else if (duration is int) {
      seconds = duration;
    } else {
      return '--:--';
    }
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _openAlbumDetail(BuildContext context, Map<String, dynamic> album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AlbumDetailPage(
          api: widget.api,
          playerService: widget.playerService,
          album: album,
        ),
      ),
    );
  }
}

class _AllSongsPage extends StatelessWidget {
  final SubsonicApi api;
  final PlayerService playerService;
  final Map<String, dynamic> artist;
  final List<Map<String, dynamic>> songs;

  const _AllSongsPage({
    required this.api,
    required this.playerService,
    required this.artist,
    required this.songs,
  });

  void _playSong(
    Map<String, dynamic> song,
    List<Map<String, dynamic>> playlist,
  ) {
    playerService.playSong(
      song,
      sourceType: 'artist',
      playlist: playlist,
    );
  }

  String _formatDuration(dynamic duration) {
    if (duration == null) return '--:--';
    int seconds;
    if (duration is String) {
      seconds = int.tryParse(duration) ?? 0;
    } else if (duration is int) {
      seconds = duration;
    } else {
      return '--:--';
    }
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  Text(
                    '全部歌曲',
                    style: AppFonts.getTextStyle(
                      text: '全部歌曲',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.8,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  final coverArtUrl = song['coverArt'] != null 
                      ? api.getCoverArtUrl(song['coverArt']) 
                      : null;
                  final currentSong = playerService.currentSong;
                  final isCurrentSong = currentSong != null && 
                      currentSong['id'] == song['id'];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _playSong(song, songs),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrentSong 
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isCurrentSong
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isCurrentSong
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  ),
                                  child: coverArtUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: coverArtUrl,
                                          fit: BoxFit.cover,
                                          width: 48,
                                          height: 48,
                                          placeholder: (context, url) => Icon(
                                            Icons.music_note_rounded,
                                            size: 24,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withOpacity(0.4),
                                          ),
                                          errorWidget: (context, url, error) => Icon(
                                            Icons.music_note_rounded,
                                            size: 24,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withOpacity(0.4),
                                          ),
                                        )
                                      : Icon(
                                          Icons.music_note_rounded,
                                          size: 24,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withOpacity(0.4),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song['title'] ?? '未知歌曲',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isCurrentSong
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.onSurface,
                                        fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      song['album'] ?? '未知专辑',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isCurrentSong
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _formatDuration(song['duration']),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllAlbumsPage extends StatelessWidget {
  final SubsonicApi api;
  final PlayerService playerService;
  final Map<String, dynamic> artist;
  final List<Map<String, dynamic>> albums;

  const _AllAlbumsPage({
    required this.api,
    required this.playerService,
    required this.artist,
    required this.albums,
  });

  void _openAlbumDetail(BuildContext context, Map<String, dynamic> album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AlbumDetailPage(
          api: api,
          playerService: playerService,
          album: album,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  Text(
                    '全部专辑',
                    style: AppFonts.getTextStyle(
                      text: '全部专辑',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.8,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: albums.length,
                itemBuilder: (context, index) {
                  final album = albums[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openAlbumDetail(context, album),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  ),
                                  child: album['coverArt'] != null
                                      ? CachedNetworkImage(
                                          imageUrl: api.getCoverArtUrl(album['coverArt']),
                                          fit: BoxFit.cover,
                                          width: 60,
                                          height: 60,
                                          placeholder: (context, url) => Icon(
                                            Icons.album,
                                            size: 32,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                          errorWidget: (context, url, error) => Icon(
                                            Icons.album,
                                            size: 32,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        )
                                      : Icon(
                                          Icons.album,
                                          size: 32,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      album['name'] ?? '未知专辑',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${album['songCount'] ?? 0} 首歌曲',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumDetailPage extends StatelessWidget {
  final SubsonicApi api;
  final PlayerService playerService;
  final Map<String, dynamic> album;

  const _AlbumDetailPage({
    required this.api,
    required this.playerService,
    required this.album,
  });

  @override
  Widget build(BuildContext context) {
    return dp.DetailPage(
      api: api,
      playerService: playerService,
      item: album,
      type: dp.DetailType.album,
    );
  }
}
