import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/subsonic_api.dart';
import 'services/player_service.dart';
import 'services/color_manager_service.dart';
import 'models/lyrics_api_type.dart';
import 'services/custom_lyrics_api_service.dart';
import 'components/mini_player.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/songs_page.dart';
import 'pages/playlists_page.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'models/lyrics_api_type.dart';
import 'utils/tonal_surface_helper.dart';
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _setupColorListeners();
  }

  void _setupColorListeners() {
    // 添加颜色变化监听器
    ColorManagerService().addListener((colorScheme) {
      // 颜色变化时触发重建，确保使用最新的颜色方案
      setState(() {});
    });
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString('themeMode');
    if (savedThemeMode != null) {
      setState(() {
        switch (savedThemeMode) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          default:
            _themeMode = ThemeMode.system;
            break;
        }
      });
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;
    switch (mode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      default:
        themeModeString = 'system';
        break;
    }
    await prefs.setString('themeMode', themeModeString);
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 使用 ColorManagerService 提供的动态颜色方案
    final lightScheme = ColorManagerService().getCurrentColorScheme(
      Brightness.light,
    );
    final darkScheme = ColorManagerService().getCurrentColorScheme(
      Brightness.dark,
    );

    return MaterialApp(
      title: '音乐播放器',
      theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
      darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
      themeMode: _themeMode,
      home: InitializerPage(setThemeMode: setThemeMode),
    );
  }
}

class InitializerPage extends StatefulWidget {
  final Function(ThemeMode) setThemeMode;

  const InitializerPage({super.key, required this.setThemeMode});

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
    await CustomLyricsApiService.initializeDefaultApis();

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
              setThemeMode: widget.setThemeMode,
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
              setThemeMode: widget.setThemeMode,
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _homePage;
  }
}

class MusicHomePage extends StatefulWidget {
  final SubsonicApi api;
  final String baseUrl;
  final String username;
  final String password;
  final Function(ThemeMode) setThemeMode;

  const MusicHomePage({
    super.key,
    required this.api,
    required this.baseUrl,
    required this.username,
    required this.password,
    required this.setThemeMode,
  });

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  int _selectedIndex = 0;
  late final PlayerService playerService;
  late Future<List<Map<String, dynamic>>> _randomSongsFuture;
  late final List<Widget> _pages;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    playerService = PlayerService(api: widget.api);
    _randomSongsFuture = widget.api.getRandomSongs(count: 9);

    _pages = [
      HomePage(
        api: widget.api,
        playerService: playerService,
        randomSongsFuture: _randomSongsFuture,
        onRefreshRandomSongs: () {
          setState(() {
            _randomSongsFuture = widget.api.getRandomSongs(count: 9);
          });
          return _randomSongsFuture;
        },
        setThemeMode: widget.setThemeMode,
      ),
      SongsPage(api: widget.api, playerService: playerService),
      PlaylistsPage(api: widget.api, playerService: playerService),
    ];

    // 初始化页面控制器
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildNavigationDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      label: label,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // 控制页面滚动到对应的索引
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 设置页面基础背景色为surface
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: _pages,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: kBottomNavigationBarHeight - 60,
            child: MiniPlayer(playerService: playerService, api: widget.api),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: NavigationBar(
          height: 64,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          indicatorColor: Theme.of(context).colorScheme.primaryContainer,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.transparent, width: 4),
          ),
          surfaceTintColor: Theme.of(context).colorScheme.surface,
          backgroundColor: Colors.transparent,
          destinations: [
            _buildNavigationDestination(
              icon: Icons.home_rounded,
              selectedIcon: Icons.home_outlined,
              label: '主页',
              index: 0,
            ),
            _buildNavigationDestination(
              icon: Icons.music_note_rounded,
              selectedIcon: Icons.music_note_outlined,
              label: '歌曲',
              index: 1,
            ),
            _buildNavigationDestination(
              icon: Icons.playlist_play_rounded,
              selectedIcon: Icons.playlist_play_outlined,
              label: '歌单',
              index: 2,
            ),
          ],
        ),
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
