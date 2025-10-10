import 'package:flutter/material.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import 'detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  void initState() {
    super.initState();
    _albumsFuture = widget.api.getAlbumsByArtist(widget.artist['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artist['name'] ?? '未知艺术家'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _albumsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载专辑失败: ${snapshot.error}'),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _albumsFuture = widget.api.getAlbumsByArtist(widget.artist['id']);
                      });
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final albums = snapshot.data ?? [];

          if (albums.isEmpty) {
            return const Center(child: Text('该艺术家暂无专辑'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.72,//修改此文件可以解决专辑图长度
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return _buildAlbumCard(album);
            },
          );
        },
      ),
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openAlbumDetail(album),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: album['coverArt'] != null
                    ? CachedNetworkImage(
                        imageUrl: widget.api.getCoverArtUrl(album['coverArt']),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.album, size: 64),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.album, size: 64),
                        ),
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.album, size: 64),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album['name'] ?? '未知专辑',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    album['artist'] ?? '未知艺术家',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${album['songCount'] ?? 0} 首歌曲',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAlbumDetail(Map<String, dynamic> album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(
          api: widget.api,
          playerService: widget.playerService,
          item: album,
          type: DetailType.album,
        ),
      ),
    );
  }
}
