import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';


//有状态组件statefulWidget,接受api实例和播放器服务
class HomePage extends StatefulWidget {

  //网络请求
  final SubsonicApi api;

  //播放控制
  final PlayerService playerService;

  final Future<List<Map<String, dynamic>>> randomSongsFuture;

  final Future<List<Map<String, dynamic>>> Function() onRefreshRandomSongs;
  
  const HomePage({
    super.key, 
    required this.api, 
    required this.playerService,
    required this.randomSongsFuture,
    required this.onRefreshRandomSongs,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  // 储存随机歌曲的future对象
  late Future<List<Map<String, dynamic>>> _randomSongsFuture;
  
  @override
  void initState() {
    super.initState();

    // 初始化时加载歌曲的数量(在initState中调用getRandomSongs加载歌曲)
    _randomSongsFuture = widget.api.getRandomSongs(count: 9);
  }

  //构建ui (核心方法)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          children: [

            // _buildMaterialYouTest(context),

            // 欢迎区域
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(

                    //根据时间显示不同的欢迎语句
                    _getGreeting(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '发现新音乐',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            
            // 快速访问区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '快速访问',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            
            // 快速访问区域--横向滚动的功能卡片列表
            //功能卡片通过 _buildFeatureCard方法统一构建，包含图标文字和点击事件
            //使用colorScheme.primary确保主题色符合MaterialYou规范
            Container(
              height: 130, // 固定高度以限制卡片区域
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(

                 // 横向滚动
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // 1. 按时间推荐
                  _buildFeatureCard(
                    context,
                    '按时间推荐',
                    Icons.access_time,
                    Theme.of(context).colorScheme.primary,
                    // Colors.blue,
                    width: 190,

                    //点击事件
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('查看按时间推荐')),
                      );
                    },
                  ),
                  const SizedBox(width: 16), // 卡片间距

                  // 2. 每日推荐
                  _buildFeatureCard(
                    context,
                    '每日推荐',
                    Icons.calendar_today,
                    Theme.of(context).colorScheme.primary,
                    // Colors.green,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('查看每日推荐')),
                      );
                    },
                  ),
                  const SizedBox(width: 16),

                  // 3. 最近播放
                  _buildFeatureCard(
                    context,
                    '最近播放',
                    Icons.history,
                    // Colors.orange,
                    Theme.of(context).colorScheme.primary,
                    onTap: _viewRecentPlays, // 复用原方法
                  ),
                  const SizedBox(width: 16),

                  // 4. 最近添加
                  _buildFeatureCard(
                    context,
                    '最近添加',
                    Icons.add,
                    // Colors.purple,
                    Theme.of(context).colorScheme.primary,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('查看最近添加')),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // 推荐歌曲区域(实际是随机歌曲，因为subsonic api没有真正的推荐歌曲接口)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Text(
                    '推荐歌曲',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),

                  //刷新按钮
                  IconButton(
                    icon: const Icon(Icons.refresh),

                    //按下按钮调用 _refreshRandomSongs
                    onPressed: _refreshRandomSongs,
                    tooltip: '刷新推荐',
                  ),
                ],
              ),
            ),
            
            // 随机歌曲列表
            _buildRandomSongsList(),
          ],
        ),
      ),
    );
  }


  //随机歌曲列表
  Widget _buildRandomSongsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      // future: _randomSongsFuture,
      future: widget.randomSongsFuture,
      builder: (context, snapshot) {
        // 加载中状态（保持不变）
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 380,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        // 错误状态（保持不变）
        if (snapshot.hasError) {
          return Container(
            height: 380,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '加载失败',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _refreshRandomSongs,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }
        
        //空数据：显示无歌曲的提示
        final songs = snapshot.data ?? [];
        // 空状态（保持不变）
        if (songs.isEmpty) {
          return Container(
            height: 380,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '暂无推荐歌曲',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }
        
        //成功状态：战士歌曲网格(核心布局)
        return Container(
          // 增加底部margin，为悬浮播放器预留空间（通常播放器高度在60-80之间）
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 80), 
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(

              //网格布局，歌曲卡片的行列数量和间隙调整
              crossAxisCount: 3,
              crossAxisSpacing: 18,
              mainAxisSpacing: 20,
              childAspectRatio: 0.65,
            ),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];

              //构建单个歌曲的卡片
              return InkWell(
                onTap: () => _playSong(song),
                borderRadius: BorderRadius.circular(12),
                splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    //歌曲封面
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: _buildSongCover(song),
                      ),
                    ),
                    const SizedBox(height: 10),

                    //歌曲信息
                    //标题
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        (song['title'] ?? '未知标题').length > 10
                            ? '${(song['title'] ?? '未知标题').substring(0, 10)}...'
                            : song['title'] ?? '未知标题',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    //艺术家
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        song['artist'] ?? '未知艺术家',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }


  //歌曲封面定义
  Widget _buildSongCover(Map<String, dynamic> song) {
    // 统一圆角值（与推荐区域容器圆角保持一致）
    final borderRadius = BorderRadius.circular(8);

    // 优先使用歌曲自身的封面
    if (song['coverArt'] != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          width: 40,
          height: 40,
          child: CachedNetworkImage(
            imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }
    
    // 如果歌曲没有封面，尝试使用专辑封面
    if (song['albumId'] != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          width: 40,
          height: 40,
          child: CachedNetworkImage(
            imageUrl: widget.api.getCoverArtUrl(song['albumId']),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }
    
    // 默认显示音乐图标（容器自带圆角）
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.music_note,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        size: 24,
      ),
    );
  }

  //快速访问卡片定义
  Widget _buildFeatureCard(
    BuildContext context, 
    String title, 
    IconData icon, 
    Color color, {
    VoidCallback? onTap,
    double? width, // 新增宽度参数，可选
  }) {
    // 默认宽度为正方形（120），如果指定了宽度则使用指定值
    final cardWidth = width ?? 120;
    
    return SizedBox(
      width: cardWidth, // 使用指定宽度
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }


  // 获取问候语
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return '深夜好!';
    } else if (hour < 12) {
      return '早上好!';
    } else if (hour < 18) {
      return '下午茶!';
    } else {
      return '晚上好!';
    }
  }

  // 播放随机歌曲
  void _playRandomSongs() async {
    try {
      final randomSongs = await widget.api.getRandomSongs(count: 5);
      if (randomSongs.isNotEmpty) {
        widget.playerService.playSong(randomSongs.first, sourceType: 'random', playlist: randomSongs);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('开始随机播放: ${randomSongs.first['title']}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('播放失败: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // 播放单首歌曲
  void _playSong(Map<String, dynamic> song) {
    // 获取当前推荐歌曲列表
    widget.randomSongsFuture.then((songs) {
      widget.playerService.playSong(
        song,
        sourceType: 'recommendation',
        playlist: songs, // 传入完整推荐列表作为播放列表
      );
    });
  }


  // 查看最近播放
  void _viewRecentPlays() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('查看最近播放')),
    );
  }

  // 刷新推荐歌曲
  void _refreshRandomSongs() {
    // 调用父组件的刷新回调并等待结果，然后触发UI更新
    widget.onRefreshRandomSongs().then((_) {
      if (mounted) {
        setState(() {}); // 强制重建UI以显示新数据
      }
    });
  }

  // 刷新所有数据
  Future<void> _refreshData() async {
    await widget.onRefreshRandomSongs();
    if (mounted) {
      setState(() {});
    }
    // setState(() {
    //   _randomSongsFuture = widget.api.getRandomSongs(count: 9);
    // });
  }
}
