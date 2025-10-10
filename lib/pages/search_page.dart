import 'package:flutter/material.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';

class SearchPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;
  
  const SearchPage({super.key, required this.api, required this.playerService});
  
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _genresFuture;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  List<String> _searchHistory = []; // 搜索历史

  @override
  void initState() {
    super.initState();
    _genresFuture = widget.api.getGenres();
    // 这里可以加载保存的搜索历史
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 搜索框
          _buildSearchBar(),
          
          if (_isSearching) 
            _buildSearchResults()
          else if (_searchController.text.isEmpty)
            _buildBrowseSection()
          else
            _buildSearchSuggestions(),
        ],
      ),
    );
  }
  
  // 构建搜索框
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索歌曲、艺术家、专辑...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          setState(() {
            // 实时搜索建议
          });
        },
        onSubmitted: (value) {
          _performSearch(value);
        },
      ),
    );
  }

  // 构建开始浏览区域
  Widget _buildBrowseSection() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 开始浏览区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '开始浏览',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 流派卡片网格
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _genresFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('加载流派中...'),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return SizedBox(
                          height: 120,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                                SizedBox(height: 8),
                                Text('加载失败'),
                                SizedBox(height: 8),
                                FilledButton.tonal(
                                  onPressed: () {
                                    setState(() {
                                      _genresFuture = widget.api.getGenres();
                                    });
                                  },
                                  child: Text('重试'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final genres = snapshot.data ?? [];
                      
                      if (genres.isEmpty) {
                        return SizedBox(
                          height: 120,
                          child: Center(
                            child: Text('暂无流派数据'),
                          ),
                        );
                      }
                      
                      // 只取前4个流派显示
                      final displayGenres = genres.length > 4 ? genres.sublist(0, 4) : genres;
                      
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: displayGenres.length,
                        itemBuilder: (context, index) {
                          final genre = displayGenres[index];
                          return _buildGenreCard(genre);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // 搜索历史区域
            if (_searchHistory.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '搜索历史',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _clearSearchHistory,
                          child: const Text('清空'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _searchHistory.map((query) {
                        return InputChip(
                          label: Text(query),
                          onPressed: () {
                            _searchController.text = query;
                            _performSearch(query);
                          },
                          onDeleted: () {
                            _removeFromSearchHistory(query);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // 快速搜索建议
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '热门搜索',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      '周杰伦', '流行', '摇滚', '古典', 
                      '电子', '爵士', '2024新歌', '华语金曲'
                    ].map((suggestion) {
                      return ActionChip(
                        label: Text(suggestion),
                        onPressed: () {
                          _searchController.text = suggestion;
                          _performSearch(suggestion);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建搜索结果
  Widget _buildSearchResults() {
    return Expanded(
      child: _searchResults.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('没有找到相关结果'),
                  SizedBox(height: 8),
                  Text('尝试其他关键词'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final song = _searchResults[index];
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(song['title'] ?? '未知标题'),
                  subtitle: Text('${song['artist'] ?? '未知艺术家'} • ${song['album'] ?? '未知专辑'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () {
                      _playSong(song);
                    },
                  ),
                  onTap: () {
                    _playSong(song);
                  },
                );
              },
            ),
    );
  }

  // 构建搜索建议
  Widget _buildSearchSuggestions() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '按下回车键搜索',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '搜索 "${_searchController.text}"',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // 将图标名称映射到 IconData
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'guitar_amplifier':
        return Icons.piano;
      case 'mic':
        return Icons.mic;
      case 'piano':
        return Icons.piano;
      case 'music_note':
        return Icons.music_note;
      case 'graphic_eq':
        return Icons.graphic_eq;
      case 'album':
        return Icons.album;
      case 'audiotrack':
        return Icons.audiotrack;
      default:
        return Icons.music_note;
    }
  }
  
  // 构建单个流派卡片
  Widget _buildGenreCard(Map<String, dynamic> genre) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onGenreTap(genre),
        child: Stack(
          children: [
            // 流派名称（左上角）
            Positioned(
              top: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    genre['name'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${genre['songCount']} 首歌曲 • ${genre['albumCount']} 张专辑',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // 乐器图标（右下角）
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconFromName(genre['iconName']),
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 执行搜索
  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    // 添加到搜索历史
    _addToSearchHistory(query);

    setState(() {
      _isSearching = true;
    });

    try {
      // 这里应该调用真正的搜索API
      // 暂时用 getAllSongsViaSearch 模拟搜索
      final allSongs = await widget.api.getAllSongsViaSearch();
      
      // 简单过滤（实际应该调用搜索API）
      final results = allSongs.where((song) {
        final title = (song['title'] ?? '').toLowerCase();
        final artist = (song['artist'] ?? '').toLowerCase();
        final album = (song['album'] ?? '').toLowerCase();
        final searchTerm = query.toLowerCase();
        
        return title.contains(searchTerm) || 
               artist.contains(searchTerm) || 
               album.contains(searchTerm);
      }).toList();

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('搜索失败: $e');
      setState(() {
        _searchResults = [];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('搜索失败: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // 播放歌曲
  void _playSong(Map<String, dynamic> song) {
    widget.playerService.playSong(song, sourceType: 'search');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('播放: ${song['title']}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // 流派点击
  void _onGenreTap(Map<String, dynamic> genre) {
    // 搜索该流派
    _searchController.text = genre['name'];
    _performSearch(genre['name']);
  }

  // 清空搜索
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults.clear();
    });
  }

  // 添加到搜索历史
  void _addToSearchHistory(String query) {
    if (!_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        // 限制历史记录数量
        if (_searchHistory.length > 10) {
          _searchHistory = _searchHistory.sublist(0, 10);
        }
      });
      // 这里可以保存到本地存储
    }
  }

  // 从搜索历史移除
  void _removeFromSearchHistory(String query) {
    setState(() {
      _searchHistory.remove(query);
    });
    // 这里可以更新本地存储
  }

  // 清空搜索历史
  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
    // 这里可以清空本地存储
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}