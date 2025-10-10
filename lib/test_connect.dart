// lib/test_connect.dart
import 'services/subsonic_api.dart';

Future<void> testConnection() async {
  print('🎵 开始测试 Navidrome 服务器连接...');
  
  final api = SubsonicApi(
    baseUrl: 'http://192.168.2.164:4533',
    username: 'otoya',
    password: '486952',
  );
  
  print('🔗 正在连接服务器...');
  bool isConnected = await api.ping();
  
  if (isConnected) {
    print('✅ 服务器连接成功！');
  } else {
    print('❌ 服务器连接失败');
  }
}

Future<void> testMusicFolders() async {
  print('\n📁 测试获取音乐库...');
  
  final api = SubsonicApi(
    baseUrl: 'http://192.168.2.164:4533',
    username: 'otoya',
    password: '486952',
  );
  
  try {
    List<Map<String, dynamic>> folders = await api.getMusicFolders();
    print('✅ 获取到 ${folders.length} 个音乐库');
    
    for (var folder in folders) {
      print('   🗂️  音乐库 ID: ${folder['id']}, 名称: ${folder['name']}');
    }
  } catch (e) {
    print('❌ 获取音乐库失败: $e');
  }
}


Future<void> testArtists() async {
  print('\n🎤 测试获取艺术家列表...');
  
  final api = SubsonicApi(
    baseUrl: 'http://192.168.2.164:4533',
    username: 'otoya',
    password: '486952',
  );
  
  try {
    var artists = await api.getArtists();
    print('✅ 获取到 ${artists.length} 位艺术家');
    
    // 只显示前10位艺术家，避免输出太长
    int displayCount = artists.length > 10 ? 10 : artists.length;
    for (int i = 0; i < displayCount; i++) {
      var artist = artists[i];
      print('   👤 艺术家: ${artist['name']} (ID: ${artist['id']})');
    }
    
    if (artists.length > 10) {
      print('   ... 还有 ${artists.length - 10} 位艺术家');
    }
    
  } catch (e) {
    print('❌ 获取艺术家列表失败: $e');
  }
}


Future<void> testRandomSongs() async {
  print('\n🎲 测试获取随机歌曲...');
  
  final api = SubsonicApi(
    baseUrl: 'http://192.168.2.164:4533',
    username: 'otoya',
    password: '486952',
  );
  
  try {
    var songs = await api.getRandomSongs(count: 5); // 先测试5首
    print('✅ 获取到 ${songs.length} 首随机歌曲');
    
    for (var song in songs) {
      print('   🎵 ${song['title']} - ${song['artist']}');
    }
  } catch (e) {
    print('❌ 获取随机歌曲失败: $e');
  }
}

Future<void> testAlbums() async {
  print('\n💿 测试获取专辑列表...');
  
  final api = SubsonicApi(
    baseUrl: 'http://192.168.2.164:4533',
    username: 'otoya',
    password: '486952',
  );
  
  try {
    var albums = await api.getAlbums();
    print('✅ 获取到 ${albums.length} 张专辑');
    
    // 显示前5张专辑
    int displayCount = albums.length > 5 ? 5 : albums.length;
    for (int i = 0; i < displayCount; i++) {
      var album = albums[i];
      print('   💿 ${album['name']} - ${album['artist']} (${album['songCount']}首)');
    }
    
    if (albums.length > 5) {
      print('   ... 还有 ${albums.length - 5} 张专辑');
    }
  } catch (e) {
    print('❌ 获取专辑列表失败: $e');
  }
}


Future<void> testAllSongs() async {
  print('\n🎵 测试获取所有歌曲（通过专辑）...');
  
  final api = SubsonicApi(
    baseUrl: 'http://192.168.2.164:4533',
    username: 'otoya',
    password: '486952',
  );
  
  try {
    var songs = await api.getAllSongs(); // 使用新方法
    print('✅ 总共获取到 ${songs.length} 首歌曲');
    
    // 显示前3首作为示例
    int displayCount = songs.length > 3 ? 3 : songs.length;
    for (int i = 0; i < displayCount; i++) {
      var song = songs[i];
      print('   🎵 ${song['title']} - ${song['artist']}');
    }
  } catch (e) {
    print('❌ 获取所有歌曲失败: $e');
  }
}

Future<void> testCreatePlaylist() async {
  print('\n➕ 测试创建播放列表...');
  
  final api = SubsonicApi(
    baseUrl: 'http://192.168.2.164:4533',
    username: 'otoya',
    password: '486952',
  );
  
  try {
    // 先获取一些随机歌曲的ID
    var randomSongs = await api.getRandomSongs(count: 3);
    if (randomSongs.isNotEmpty) {
      var songIds = randomSongs.map((song) => song['id'] as String).toList();
      bool success = await api.createPlaylist('测试播放列表', songIds);
      
      if (success) {
        // 重新获取播放列表查看结果
        var playlists = await api.getPlaylists();
        print('✅ 现在有 ${playlists.length} 个播放列表');
      }
    }
  } catch (e) {
    print('❌ 创建播放列表失败: $e');
  }
}

Future<void> testPlaylists() async {
  print('\n📋 测试获取播放列表...');
  
  final api = SubsonicApi(
    baseUrl: 'http://192.168.2.164:4533',
    username: 'otoya',
    password: '486952',
  );
  
  try {
    var playlists = await api.getPlaylists();
    print('✅ 获取到 ${playlists.length} 个播放列表');
    
    for (var playlist in playlists) {
      print('   📝 ${playlist['name']} (${playlist['songCount']}首)');
    }
  } catch (e) {
    print('❌ 获取播放列表失败: $e');
  }
}


Future<void> testAllSongsViaSearch() async {
  print('\n🔍 测试通过搜索获取所有歌曲...');
  
  final api = SubsonicApi(
    baseUrl: 'http://192.168.2.164:4533',
    username: 'otoya',
    password: '486952',
  );
  
  try {
    var songs = await api.getAllSongsViaSearch();
    print('✅ 通过搜索获取到 ${songs.length} 首歌曲');
    
    int displayCount = songs.length > 5 ? 5 : songs.length;
    for (int i = 0; i < displayCount; i++) {
      var song = songs[i];
      print('   🎵 ${song['title']} - ${song['artist']}');
    }
    
    if (songs.length > 5) {
      print('   ... 还有 ${songs.length - 5} 首歌曲');
    }
  } catch (e) {
    print('❌ 搜索所有歌曲失败: $e');
  }
}




void main() async {
  await testConnection();
  await testMusicFolders();
  await testArtists();
  await testRandomSongs();
  await testAlbums();
  await testAllSongsViaSearch();
  // await testAllSongs();
  await testPlaylists();
  await testCreatePlaylist();

}