import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/subsonic_api.dart';
import 'services/player_service.dart';
import 'components/mini_player.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/library_page.dart';
import 'pages/login_page.dart';
import 'package:dynamic_color/dynamic_color.dart';
// import 'package:just_audio_background/just_audio_background.dart';
// import 'package:audio_session/audio_session.dart';  // 新增


//应用入口
// void main() {
//   runApp(const MyApp());
// }

// Future<void> main() async {
//   // 初始化后台播放服务
//   await JustAudioBackground.init(
//     androidNotificationChannelId: 'com.example.minemusic.channel.audio',
//     androidNotificationChannelName: 'MineMusic',
//     // 播放时通知常驻
//     androidNotificationOngoing: true,
//     androidStopForegroundOnPause: true,
//     // 可选：设置通知图标（需在mipmap中添加）
//     androidNotificationIcon: 'mipmap/ic_launcher',
//     androidNotificationClickStartsActivity: true,
//     androidResumeOnClick: true,
//   );

//   // 配置音频会话（确保后台播放时音频焦点）
//   final session = await AudioSession.instance;
//   await session.configure(const AudioSessionConfiguration.music());

//   runApp(const MyApp());
// }


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 不再需要 JustAudioBackground 初始化
  runApp(const MyApp());
}

// 其他代码保持不变...


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightScheme = lightDynamic;
          darkScheme = darkDynamic;
        } else {
          lightScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          );
        }
        
        return MaterialApp(
          title: '音乐播放器',
          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          home: const InitializerPage(),
        );
      },
    );
  }
}


class InitializerPage extends StatefulWidget {
  const InitializerPage({super.key});

  @override
  State<InitializerPage> createState() => _InitializerPageState();
}

class _InitializerPageState extends State<InitializerPage> {
  bool _isLoading = true;
  Widget _homePage = const SizedBox();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('baseUrl');
      final username = prefs.getString('username');
      final password = prefs.getString('password');

      if (baseUrl != null && username != null && password != null) {
        final api = SubsonicApi(
          baseUrl: baseUrl,
          username: username,
          password: password,
        );

        final success = await api.ping();
        if (success) {
          setState(() {
            _homePage = MusicHomePage(
              api: api,
              baseUrl: baseUrl,
              username: username,
              password: password,
            );
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('自动登录失败: $e');
    }

    setState(() {
      _homePage = LoginPage(
        onLoginSuccess: (api, baseUrl, username, password) {
          setState(() {
            _homePage = MusicHomePage(
              api: api,
              baseUrl: baseUrl,
              username: username,
              password: password,
            );
          });
        },
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _homePage;
  }
}


class MusicHomePage extends StatefulWidget {
  final SubsonicApi api;
  final String baseUrl;
  final String username;
  final String password;

  const MusicHomePage({
    super.key,
    required this.api,
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  int _selectedIndex = 0;
  late final PlayerService playerService;
  late Future<List<Map<String, dynamic>>> _randomSongsFuture;

  final ScrollController _scrollController = ScrollController();
  bool _isAppBarVisible = true;
  double _lastScrollPosition = 0;

  // 关键修改：将_pages从固定列表改为动态生成的getter
  List<Widget> get _pages => [
        HomePage(
          key: ValueKey(_randomSongsFuture), // 每次future变化，Key也会变化
          api: widget.api, 
          playerService: playerService,
          randomSongsFuture: _randomSongsFuture,
          onRefreshRandomSongs: () {
            setState(() {
              _randomSongsFuture = widget.api.getRandomSongs(count: 9);
            });
            return _randomSongsFuture;
          },
          scrollController: _scrollController,
        ),
        SearchPage(
          api: widget.api, 
          playerService: playerService, 
        ),
        LibraryPage(
          api: widget.api, 
          playerService: playerService, 
          scrollController: _scrollController
        ),
      ];

  @override
  void initState() {
    super.initState();
    playerService = PlayerService(api: widget.api);
    _randomSongsFuture = widget.api.getRandomSongs(count: 9);
    // 移除initState中的_pages初始化，改为通过getter动态生成

    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 释放资源
    super.dispose();
  }

  // 处理滚动逻辑
  void _handleScroll() {
    final currentPosition = _scrollController.position.pixels;
    
    // 向上滚动且超过一定距离时隐藏AppBar
    if (currentPosition > _lastScrollPosition && currentPosition > 100) {
      if (_isAppBarVisible) {
        setState(() => _isAppBarVisible = false);
      }
    } 
    // 向下滚动时显示AppBar
    else if (currentPosition < _lastScrollPosition - 20) {
      if (!_isAppBarVisible) {
        setState(() => _isAppBarVisible = true);
      }
    }
    
    _lastScrollPosition = currentPosition;
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('baseUrl');
    await prefs.remove('username');
    await prefs.remove('password');
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InitializerPage()),
      );
    }
  }




  @override
  Widget build (BuildContext context) {
    
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: _isAppBarVisible ? 
      AppBar(
        title: const Text('MineMusic'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '退出登录',
          ),
        ],
      )
      : null,

      // 关键修改：用SingleChildScrollView包裹页面内容并绑定控制器
      body: Stack(
        children: [
        Padding(
          padding: EdgeInsets.only(top: _isAppBarVisible ? 0 : statusBarHeight),
          child: _pages[_selectedIndex],
        ),
          // _pages[_selectedIndex],
          // SingleChildScrollView(
          //   controller: _scrollController,
          //   child: SizedBox(
          //     // 确保滚动区域高度足够
          //     height: MediaQuery.of(context).size.height,
          //     child: _pages[_selectedIndex],
          //   ),
          // ),

          Positioned(
            left: 0,
            right: 0,
            bottom: kBottomNavigationBarHeight - 60,
            child: MiniPlayer(playerService: playerService, api: widget.api),
          ),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.transparent, width: 4),
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            selectedIcon: Icon(Icons.home_outlined),
            label: '主页',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_outlined),
            label: '搜索',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_rounded),
            selectedIcon: Icon(Icons.library_music_outlined),
            label: '音乐库',
          ),
        ],
      ),
    );
  }
}





//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: _isAppBarVisible ? 
//       AppBar(
//         title: const Text('MineMusic'),
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: _logout,
//             tooltip: '退出登录',
//           ),
//         ],
//       )
//       : null,


      
//       body: Stack(
//         children: [
//           _pages[_selectedIndex], // 使用动态生成的页面列表
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: kBottomNavigationBarHeight - 60,
//             child: MiniPlayer(playerService: playerService, api: widget.api),
//           ),
//         ],
//       ),



//       bottomNavigationBar: NavigationBar(
//         height: 64,
//         selectedIndex: _selectedIndex,
//         onDestinationSelected: _onItemTapped,
//         // 选中项背景色（使用主题色，更贴合 Material 3）
//         indicatorColor: Theme.of(context).colorScheme.primaryContainer,
//         // 控制选中项的椭圆形状（通过 RoundedRectangleBorder 的 borderRadius 和 side 间接控制内边距效果）
//         indicatorShape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//           // 可以通过透明边框模拟内边距效果（可选）
//           side: const BorderSide(color: Colors.transparent, width: 4),
//         ),
//         destinations: const [
//           NavigationDestination(
//             icon: Icon(Icons.home_rounded), // 未选中用轮廓图标
//             selectedIcon: Icon(Icons.home_outlined), // 选中用填充图标
//             label: '主页',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.search_rounded),
//             selectedIcon: Icon(Icons.search_outlined),
//             label: '搜索',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.library_music_rounded),
//             selectedIcon: Icon(Icons.library_music_outlined),
//             label: '音乐库',
//           ),
//         ],
//       ),
//     );
//   }
// }
