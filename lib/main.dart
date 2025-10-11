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


//应用入口
//runApp方法将根组件 MyApp 渲染到屏幕上
void main() {
  runApp(const MyApp());
}



//StatelessWidget:无状态，ui不随数据变化
//StatefulWidget:有状态，通过 setState 更新ui
//playerService构造函数传递服务，实现跨组件通信

//根组件，应用配置(应用主题以及路由配置)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    //实现MaterialYou动态配色
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
        
        //MaterialApp配置[应用主题 标题 初始页面]
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


//初始化页面，处理自动登录逻辑
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

    //初始化应用，检查登录状态
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {

      //从本地存储读取登录信息，功能由 SharedPreferences 包实现
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('baseUrl');
      final username = prefs.getString('username');
      final password = prefs.getString('password');


      //如果本地有存储信息，尝试自动登录
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

    // 如果本地没有保存的信息或自动登录失败，显示登录页面
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


//主页面容器，管理底部导航和播放器
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

  //底部导航栏选中索引
  int _selectedIndex = 0;

  //播放器服务
  late final PlayerService playerService;

  //底部导航页面列表
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();

    //初始化播放器服务
    playerService = PlayerService(api: widget.api);

    //初始化导航页面
    _pages.addAll([
      HomePage(api: widget.api, playerService: playerService),
      SearchPage(api: widget.api, playerService: playerService),
      LibraryPage(api: widget.api, playerService: playerService),
    ]);
  }

  //切换底部导航栏
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

      //层叠布局：主页面+底部迷你悬浮播放器
      body: Stack(
        children: [

          //当前选中的页面
          _pages[_selectedIndex],

          //固定在底部的迷你悬浮播放器
          Positioned(
            left: 0,
            right: 0,
            bottom: kBottomNavigationBarHeight - 60,
            child: MiniPlayer(playerService: playerService, api: widget.api),
          ),
        ],
      ),

      //底部导航栏
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