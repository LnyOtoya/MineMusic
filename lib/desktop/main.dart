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
import '../pages/settings_page.dart';
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
      body: Column(
        children: [
          // Top Bar (across entire app)
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Left: Logo and Player name
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.music_note_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'MineMusic',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 48),

                  // Center: Home button and search box
                  Expanded(
                    child: Row(
                      children: [
                        // Home button
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: TextButton.icon(
                            onPressed: () => _onDestinationSelected(0),
                            icon: Icon(
                              Icons.home_rounded,
                              size: 18,
                              color: _selectedIndex == 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            label: Text(
                              '主页',
                              style: TextStyle(
                                color: _selectedIndex == 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: _selectedIndex == 0
                                  ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withOpacity(0.3)
                                  : Colors.transparent,
                            ),
                          ),
                        ),

                        // Search box (shorter width)
                        Container(
                          width: 400,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                _onDestinationSelected(1);
                                // TODO: Pass search query to search page
                              }
                            },
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              hintText: '搜索音乐、艺术家、专辑...',
                              hintStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Right: Settings button
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsPage(
                            api: widget.api,
                            playerService: playerService,
                            setThemeMode: widget.setThemeMode,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.settings_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content area
          Expanded(
            child: Row(
              children: [
                DesktopSidebar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  api: widget.api,
                  playerService: playerService,
                  setThemeMode: widget.setThemeMode,
                ),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),

          // Player Bar (across entire app)
          DesktopPlayerBar(playerService: playerService, api: widget.api),
        ],
      ),
    );
  }
}
