import 'package:flutter/material.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import 'artist_detail_page.dart';

class ArtistsPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;
  
  const ArtistsPage({super.key, required this.api, required this.playerService});
  
  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  late Future<List<Map<String, dynamic>>> _artistsFuture;

  @override
  void initState() {
    super.initState();
    _artistsFuture = widget.api.getArtists();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _artistsFuture,
      builder: (context, snapshot) {
        // 加载中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('加载艺术家列表中...'),
              ],
            ),
          );
        }

        // 出错
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('加载失败: ${snapshot.error}'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _artistsFuture = widget.api.getArtists();
                    });
                  },
                  child: Text('重试'),
                ),
              ],
            ),
          );
        }

        // 成功加载数据
        final artists = snapshot.data ?? [];
        
        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return ListTile(
              leading: const Icon(Icons.person, size: 32),
              title: Text(
                artist['name'] ?? '未知艺术家',
                style: const TextStyle(fontSize: 16),
              ),
              subtitle: Text('专辑数: ${artist['albumCount'] ?? 0}'),
              // subtitle: Text('ID: ${artist['id']}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArtistDetailPage(api: widget.api, playerService: widget.playerService, artist: artist),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
