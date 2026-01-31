import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import '../services/color_manager_service.dart';
import '../models/lyrics_api_type.dart';
import '../services/custom_lyrics_api_service.dart';
import 'pages/desktop_home_page.dart';
import 'pages/desktop_login_page.dart';
import 'pages/desktop_search_page.dart';
import 'pages/desktop_library_page.dart';
import 'pages/desktop_playlists_page.dart';
import 'components/desktop_sidebar.dart';
import 'components/desktop_player_bar.dart';
import 'package:dynamic_color/dynamic_color.dart';
import '../utils/tonal_surface_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DesktopApp());
}

class DesktopApp extends StatefulWidget {
  const DesktopApp({super.key});

  @override
  State<DesktopApp> createState() => _DesktopAppState();
}

class _DesktopAppState extends State<DesktopApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _setupColorListeners();
  }

  void _setupColorListeners() {
    ColorManagerService().addListener((colorScheme) {
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
    final lightScheme = ColorManagerService().getCurrentColorScheme(
      Brightness.light,
    );
    final darkScheme = ColorManagerService().getCurrentColorScheme(
      Brightness.dark,
    );

    return MaterialApp(
      title: 'MineMusic Desktop',
      theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
      darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
      themeMode: _themeMode,
      home: DesktopInitializerPage(setThemeMode: setThemeMode),
    );
  }
}

class DesktopInitializerPage extends StatefulWidget {
  final Function(ThemeMode) setThemeMode;

  const DesktopInitializerPage({super.key, required this.setThemeMode});

  @override
  State<DesktopInitializerPage> createState() => _DesktopInitializerPageState();
}

class _DesktopInitializerPageState extends State<DesktopInitializerPage> {
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
            _homePage = DesktopMainPage(
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
      _homePage = DesktopLoginPage(
        onLoginSuccess: (api, baseUrl, username, password) {
          setState(() {
            _homePage = DesktopMainPage(
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
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _homePage;
  }
}

class DesktopMainPage extends StatefulWidget {
  final SubsonicApi api;
  final String baseUrl;
  final String username;
  final String password;
  final Function(ThemeMode) setThemeMode;

  const DesktopMainPage({
    super.key,
    required this.api,
    required this.baseUrl,
    required this.username,
    required this.password,
    required this.setThemeMode,
  });

  @override
  State<DesktopMainPage> createState() => _DesktopMainPageState();
}

class _DesktopMainPageState extends State<DesktopMainPage> {
  late final PlayerService playerService;
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    playerService = PlayerService(api: widget.api);

    _pages = [
      DesktopHomePage(
        api: widget.api,
        playerService: playerService,
        setThemeMode: widget.setThemeMode,
      ),
      DesktopSearchPage(api: widget.api, playerService: playerService),
      DesktopLibraryPage(api: widget.api, playerService: playerService),
      DesktopPlaylistsPage(api: widget.api, playerService: playerService),
    ];
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          DesktopSidebar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            api: widget.api,
            playerService: playerService,
            setThemeMode: widget.setThemeMode,
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _pages[_selectedIndex]),
                DesktopPlayerBar(playerService: playerService, api: widget.api),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
