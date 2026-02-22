import 'package:flutter/material.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/error_handler_service.dart';
import '../services/color_extraction_service.dart';
import '../widgets/animated_list_item.dart';
import '../utils/app_fonts.dart';
import 'package:mini_music_visualizer/mini_music_visualizer.dart';

enum DetailType { album, artist, playlist }

class DetailPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;
  final Map<String, dynamic> item;
  final DetailType type;
  final String? sourceType;
  final Function()? onPlaylistUpdated;

  const DetailPage({
    super.key,
    required this.api,
    required this.playerService,
    required this.item,
    required this.type,
    this.sourceType,
    this.onPlaylistUpdated,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<List<Map<String, dynamic>>> _songsFuture;
  final ColorExtractionService _colorService = ColorExtractionService();

  @override
  void initState() {
    super.initState();
    _loadSongs();
    widget.playerService.addListener(_onPlayerStateChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _extractColorFromCoverArt();
        }
      });
    });
  }

  @override
  void dispose() {
    widget.playerService.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSongs() async {
    print('加载歌曲，类型: ${widget.type}, ID: ${widget.item['id']}');
    switch (widget.type) {
      case DetailType.album:
        _songsFuture = widget.api.getSongsByAlbum(widget.item['id']);
        break;
      case DetailType.artist:
        _songsFuture = widget.api.getSongsByArtist(widget.item['id']);
        break;
      case DetailType.playlist:
        _songsFuture = widget.api.getPlaylistSongs(widget.item['id']);
        break;
    }
  }

  Future<void> _extractColorFromCoverArt() async {
    final coverArt = widget.item['coverArt'];
    
    if (coverArt == null || coverArt.isEmpty) {
      print('封面为空，跳过颜色提取');
      return;
    }

    final brightness = Theme.of(context).brightness;
    final imageUrl = widget.api.getCoverArtUrl(coverArt);
    
    print('开始提取颜色: $imageUrl');
    
    final colorScheme = await _colorService.getColorSchemeFromImage(
      imageUrl,
      brightness,
    );

    if (colorScheme != null) {
      print('颜色提取成功，更新颜色方案');
      widget.playerService.updateColorScheme(colorScheme);
    } else {
      print('颜色提取失败');
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _playSong(
    Map<String, dynamic> song,
    List<Map<String, dynamic>> playlist,
  ) {
    widget.playerService.playSong(
      song,
      sourceType: widget.sourceType ?? widget.type.toString().split('.').last,
      playlist: playlist,
    );
  }

  void _showSongMenu(Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        if (widget.type == DetailType.playlist) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_rounded),
                title: const Text('从歌单中删除'),
                onTap: () {
                  Navigator.pop(context);
                  _removeSongFromPlaylist(song);
                },
              ),
            ],
          );
        } else {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded),
                title: const Text('播放'),
                onTap: () {
                  Navigator.pop(context);
                  _playSong(song, [song]);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('加入歌单'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylistDialog(song);
                },
              ),
            ],
          );
        }
      },
    );
  }

  void _showAddToPlaylistDialog(Map<String, dynamic> song) async {
    try {
      List<Map<String, dynamic>> playlists = await widget.api.getPlaylists();
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('加入歌单'),
            content: SizedBox(
              height: 300,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return ListTile(
                    title: Text(playlist['name'] ?? '未知歌单'),
                    subtitle: Text('歌曲数: ${playlist['songCount'] ?? 0}'),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        bool success = await widget.api.addSongToPlaylist(
                          playlist['id'],
                          song['id'],
                        );
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('歌曲已添加到歌单 "${playlist['name']}"'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('添加歌曲到歌单失败')),
                          );
                        }
                      } catch (e) {
                        ErrorHandlerService().handleApiError(context, e, 'addSongToPlaylist');
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ErrorHandlerService().handleApiError(context, e, 'getPlaylists');
    }
  }

  void _removeSongFromPlaylist(Map<String, dynamic> song) async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('从歌单中删除'),
            content: Text('确定要从歌单中删除歌曲 "${song['title']}" 吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    bool success = await widget.api.removeSongFromPlaylist(
                      widget.item['id'],
                      song['id'],
                    );
                    if (success) {
                      _loadSongs();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('歌曲已从歌单中删除')));
                    } else {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('删除歌曲失败')));
                    }
                  } catch (e) {
                    ErrorHandlerService().handleApiError(context, e, 'removeSongFromPlaylist');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.error.withOpacity(0.8),
                ),
                child: const Text('删除'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ErrorHandlerService().handleApiError(context, e, 'removeSongFromPlaylist');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.item['name'] ?? '未知名称';
    final String subtitle = widget.type == DetailType.album
        ? widget.item['artist'] ?? '未知艺术家'
        : widget.type == DetailType.artist
        ? '艺术家作品'
        : '歌单歌曲';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
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
                          Text('加载失败: ${snapshot.error}'),
                          TextButton(
                            onPressed: () => _loadSongs(),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    );
                  }

                  final songs = snapshot.data ?? [];

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Row(
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
                                child: widget.type == DetailType.album
                                    ? widget.item['coverArt'] != null
                                          ? CachedNetworkImage(
                                              imageUrl: widget.api.getCoverArtUrl(
                                                widget.item['coverArt'],
                                              ),
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Icon(
                                                Icons.album,
                                                size: 60,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                              errorWidget: (context, url, error) =>
                                                  Icon(
                                                    Icons.album,
                                                    size: 60,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onSurfaceVariant,
                                                  ),
                                            )
                                          : Icon(
                                              Icons.album,
                                              size: 60,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                              )
                                    : widget.type == DetailType.artist
                                    ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      )
                                    : Icon(
                                        Icons.playlist_play,
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
                                    '专辑',
                                    style: AppFonts.getTextStyle(
                                      text: '专辑',
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    title,
                                    style: AppFonts.getTextStyle(
                                      text: title,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    subtitle,
                                    style: AppFonts.getTextStyle(
                                      text: subtitle,
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${songs.length} 首歌曲',
                                    style: AppFonts.getTextStyle(
                                      text: '${songs.length} 首歌曲',
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                              cacheExtent: 500,
                              itemCount: songs.length,
                              itemBuilder: (context, index) {
                                final song = songs[index];
                                final coverArtUrl = song['coverArt'] != null 
                                    ? widget.api.getCoverArtUrl(song['coverArt']) 
                                    : null;
                                final currentSong = widget.playerService.currentSong;
                                final isCurrentSong = currentSong != null && 
                                    currentSong['id'] == song['id'];
                                final isPlaying = isCurrentSong && widget.playerService.isPlaying;
                                
                                return AnimatedListItem(
                                  index: index,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _playSong(song, songs),
                                        onLongPress: () => _showSongMenu(song),
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
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
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
                                                        fontWeight: FontWeight.w500,
                                                        color: isCurrentSong
                                                            ? Theme.of(context).colorScheme.onPrimaryContainer
                                                            : Theme.of(context).colorScheme.onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      song['artist'] ?? '未知艺术家',
                                                      style: AppFonts.getTextStyle(
                                                        text: song['artist'] ?? '未知艺术家',
                                                        fontSize: 14,
                                                        color: isCurrentSong
                                                            ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                                            : Theme.of(context).colorScheme.onSurfaceVariant,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isPlaying)
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 8),
                                                  child: MiniMusicVisualizer(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    width: 12,
                                                    height: 16,
                                                    animate: true,
                                                    radius: 2,
                                                  ),
                                                ),
                                              Text(
                                                _formatDuration(
                                                  int.tryParse(song['duration'] ?? '0') ?? 0,
                                                ),
                                                style: AppFonts.getTextStyle(
                                                  text: _formatDuration(
                                                    int.tryParse(song['duration'] ?? '0') ?? 0,
                                                  ),
                                                  fontSize: 14,
                                                  color: isCurrentSong
                                                      ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                      ),
                    ],
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
