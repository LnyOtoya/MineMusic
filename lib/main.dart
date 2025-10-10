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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // 使用动态配色
          lightScheme = lightDynamic;
          darkScheme = darkDynamic;
        } else {
          // 回退到默认配色
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
  Widget _homePage = const SizedBox(); // 初始化为空容器

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
        // 有保存的凭据，尝试自动登录
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

    // 没有保存的凭据或自动登录失败，显示登录页面
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
        body: Center(
          child: CircularProgressIndicator(),
        ),
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
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    playerService = PlayerService(api: widget.api);
    _pages.addAll([
      HomePage(api: widget.api, playerService: playerService),
      SearchPage(api: widget.api, playerService: playerService),
      LibraryPage(api: widget.api, playerService: playerService),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  // 退出登录
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MineMusic'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '退出登录',
          ),
        ],
      ),
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: kBottomNavigationBarHeight - 60,
            child: MiniPlayer(playerService: playerService, api: widget.api),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '主页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '搜索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: '音乐库',
          ),
        ],
      ),
    );
  }
}