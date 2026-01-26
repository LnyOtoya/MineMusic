import 'package:flutter/material.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum DetailType { album, artist, playlist }

class DetailPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;
  final Map<String, dynamic> item;
  final DetailType type;
  final String? sourceType;

  const DetailPage({
    super.key,
    required this.api,
    required this.playerService,
    required this.item,
    required this.type,
    this.sourceType,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<List<Map<String, dynamic>>> _songsFuture;
  String _totalDuration = "--:--";

  @override
  void initState() {
    super.initState();
    _loadSongs();
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

    // 计算总时长
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

  // 显示歌曲操作菜单
  void _showSongMenu(Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        if (widget.type == DetailType.playlist) {
          // 歌单详情页菜单
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
          // 其他页面菜单
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

  // 显示添加到歌单对话框
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
                      // 将歌曲添加到歌单
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
      print('获取歌单列表失败: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('获取歌单列表失败')));
    }
  }

  // 从歌单中删除歌曲
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
                  // 调用API删除歌曲
                  bool success = await widget.api.removeSongFromPlaylist(
                    widget.item['id'],
                    song['id'],
                  );
                  if (success) {
                    // 重新加载歌单
                    _loadSongs();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('歌曲已从歌单中删除')));
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('删除歌曲失败')));
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
      print('从歌单中删除歌曲失败: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除歌曲失败')));
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
          Icons.playlist_play,
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
    final String title = widget.item['name'] ?? '未知名称';
    final String subtitle = widget.type == DetailType.album
        ? widget.item['artist'] ?? '未知艺术家'
        : widget.type == DetailType.artist
        ? '艺术家作品'
        : '歌单歌曲';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == DetailType.album
              ? '专辑详情'
              : widget.type == DetailType.artist
              ? '艺人详情'
              : '歌单详情',
        ),
      ),
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
                  Text('加载失败: ${snapshot.error}'),
                  TextButton(
                    onPressed: () => _loadSongs(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          // 在 detail_page.dart 的 build 方法中
          if (snapshot.hasData) {
            final songs = snapshot.data ?? [];
            print('${widget.type} 详情页获取到 ${songs.length} 首歌曲');

            if (songs.isEmpty) {
              return const Center(child: Text('暂无歌曲'));
            }

            // 正常显示歌曲列表...
          }

          final songs = snapshot.data ?? [];

          return Column(
            children: [
              // 顶部信息区域
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // 专辑/艺人/歌单图片
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: widget.type == DetailType.album
                            ? widget.item['coverArt'] != null
                                  ? CachedNetworkImage(
                                      imageUrl: widget.api.getCoverArtUrl(
                                        widget.item['coverArt'],
                                      ),
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Icon(
                                        Icons.album,
                                        size: 100,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Icon(
                                            Icons.album,
                                            size: 100,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    )
                                  : Icon(
                                      Icons.album,
                                      size: 100,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    )
                            : widget.type == DetailType.artist
                            ? Icon(
                                Icons.person,
                                size: 100,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              )
                            : _buildPlaylistCoverGrid(songs),
                      ),

                      // child: widget.type == DetailType.album
                      //     ? const Icon(Icons.album, size: 100)
                      //     : widget.type == DetailType.artist
                      //         ? const Icon(Icons.person, size: 100)
                      //         : const Icon(Icons.playlist_play, size: 100),
                    ),
                    const SizedBox(height: 24),
                    // 标题和信息
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          if (widget.type == DetailType.playlist &&
                              widget.item['comment'] != null &&
                              widget.item['comment'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                widget.item['comment'],
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            '${songs.length} 首歌曲 • 总时长: $_totalDuration',
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
                  ],
                ),
              ),
              // 歌曲列表
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                  itemCount: songs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _playSong(song, songs),
                        onLongPress: () => _showSongMenu(song),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '${index + 1}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song['title'] ?? '未知标题',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.type == DetailType.artist
                                          ? '${song['album'] ?? '未知专辑'}'
                                          : '${song['artist'] ?? '未知艺术家'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                _formatDuration(
                                  int.tryParse(song['duration'] ?? '0') ?? 0,
                                ),
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
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
