import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import '../models/lyrics_api_type.dart';
import 'login_page.dart';
import 'custom_api_config_page.dart';
import 'about_page.dart';

class SettingsPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;
  final Function(ThemeMode) setThemeMode;

  const SettingsPage({
    super.key,
    required this.api,
    required this.playerService,
    required this.setThemeMode,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ThemeMode _currentThemeMode = ThemeMode.system;
  LyricsApiType _currentLyricsApiType = LyricsApiType.disabled;
  bool _lyricsEnabled = false;
  bool _isLyricsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadLyricsApiType();
    _loadLyricsEnabled();

    PlayerService.lyricsApiTypeNotifier.addListener(_onLyricsSettingsChanged);
    PlayerService.lyricsEnabledNotifier.addListener(_onLyricsSettingsChanged);
  }

  void _onLyricsSettingsChanged() {
    setState(() {
      _currentLyricsApiType = PlayerService.lyricsApiTypeNotifier.value;
      _lyricsEnabled = PlayerService.lyricsEnabledNotifier.value;
      _isLyricsExpanded = _lyricsEnabled;
    });
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString('themeMode');
    if (savedThemeMode != null) {
      setState(() {
        switch (savedThemeMode) {
          case 'light':
            _currentThemeMode = ThemeMode.light;
            break;
          case 'dark':
            _currentThemeMode = ThemeMode.dark;
            break;
          default:
            _currentThemeMode = ThemeMode.system;
        }
      });
    }
  }

  Future<void> _loadLyricsApiType() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLyricsApiType = prefs.getString('lyricsApiType');
    if (savedLyricsApiType != null) {
      setState(() {
        _currentLyricsApiType = LyricsApiTypeExtension.fromString(
          savedLyricsApiType,
        );
      });
    }
  }

  Future<void> _loadLyricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLyricsEnabled = prefs.getBool('lyricsEnabled') ?? false;
    setState(() {
      _lyricsEnabled = savedLyricsEnabled;
      _isLyricsExpanded = savedLyricsEnabled;
    });
  }

  Future<void> _saveLyricsEnabled(bool enabled) async {
    await PlayerService.setLyricsEnabled(enabled);
    if (!enabled) {
      await PlayerService.setLyricsApiType(LyricsApiType.disabled);
    }
  }

  Future<void> _saveLyricsApiType(LyricsApiType type) async {
    await PlayerService.setLyricsApiType(type);
    if (type != LyricsApiType.disabled) {
      await PlayerService.setLyricsEnabled(true);
    }
  }

  @override
  void dispose() {
    PlayerService.lyricsApiTypeNotifier.removeListener(
      _onLyricsSettingsChanged,
    );
    PlayerService.lyricsEnabledNotifier.removeListener(
      _onLyricsSettingsChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('账户', [
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('用户名'),
              subtitle: Text(widget.api.username),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_rounded),
              title: const Text('服务器地址'),
              subtitle: Text(
                widget.api.baseUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('外观', [
            ListTile(
              leading: const Icon(Icons.brightness_6_rounded),
              title: const Text('主题模式'),
              subtitle: Text(_getThemeModeText()),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _showThemeModeDialog();
              },
            ),
            ExpansionTile(
              leading: const Icon(Icons.lyrics_rounded),
              title: const Text('歌词设置'),
              subtitle: Text(_lyricsEnabled ? '已启用 - ${_currentLyricsApiType.displayName}' : '已禁用'),
              initiallyExpanded: _isLyricsExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _isLyricsExpanded = expanded;
                });
              },
              children: [
                SwitchListTile(
                  title: const Text('启用歌词'),
                  value: _lyricsEnabled,
                  onChanged: (value) async {
                    await _saveLyricsEnabled(value);
                    setState(() {
                      _isLyricsExpanded = value;
                    });
                  },
                ),
                if (_lyricsEnabled) ...[
                  const Divider(),
                  ListTile(
                    title: const Text('歌词API'),
                    subtitle: Text(_currentLyricsApiType.displayName),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      _showLyricsApiDialog();
                    },
                  ),
                  ListTile(
                    title: const Text('自定义API配置'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomApiConfigPage(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('缓存', [
            ListTile(
              leading: const Icon(Icons.storage_rounded),
              title: const Text('清除缓存'),
              subtitle: const Text('清除所有缓存数据'),
              onTap: () {
                _confirmClearCache();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sd_storage_rounded),
              title: const Text('缓存大小限制'),
              subtitle: Text(_getCurrentCacheSizeLimitText()),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _showCacheSizeLimitDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('当前缓存大小'),
              subtitle: FutureBuilder<int>(
                future: widget.api.calculateCurrentCacheSize(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final sizeInMB = snapshot.data! / (1024 * 1024);
                    return Text('${sizeInMB.toStringAsFixed(2)}MB');
                  } else {
                    return const Text('计算中...');
                  }
                },
              ),
              enabled: false,
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('其他', [
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('关于'),
              subtitle: const Text('MineMusic v1.1.4'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),
          ]),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _logout,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  String _getCurrentCacheSizeLimitText() {
    final limit = widget.api.getCacheSizeLimit();
    if (limit == 0) {
      return '无限制';
    } else {
      final limitInGB = limit / (1024 * 1024 * 1024);
      return '${limitInGB.toStringAsFixed(1)}GB';
    }
  }

  void _showCacheSizeLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('缓存大小限制'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.api.getCacheSizeOptions().entries.map((entry) {
            return RadioListTile<int>(
              title: Text(entry.key),
              value: entry.value,
              groupValue: widget.api.getCacheSizeLimit(),
              onChanged: (value) async {
                if (value != null) {
                  await widget.api.saveCacheSizeLimit(value);
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('缓存大小限制已设置为: ${entry.key}')),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除所有缓存数据吗？这将删除所有已缓存的专辑、艺术家和播放列表数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // 显示加载对话框
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  title: Text('清除缓存'),
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('正在清除缓存...'),
                    ],
                  ),
                ),
              );
              
              // 清除缓存
              await widget.api.clearAllCache();
              
              // 关闭加载对话框
              Navigator.pop(context);
              
              // 显示成功消息
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('缓存已成功清除')),
              );
              
              // 刷新页面以更新当前缓存大小
              setState(() {});
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _getThemeModeText() {
    switch (_currentThemeMode) {
      case ThemeMode.light:
        return '亮色模式';
      case ThemeMode.dark:
        return '暗色模式';
      default:
        return '跟随系统';
    }
  }

  void _showThemeModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: _currentThemeMode,
              onChanged: (value) {
                if (value != null) {
                  widget.setThemeMode(value);
                  setState(() {
                    _currentThemeMode = value;
                  });
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('亮色模式'),
              value: ThemeMode.light,
              groupValue: _currentThemeMode,
              onChanged: (value) {
                if (value != null) {
                  widget.setThemeMode(value);
                  setState(() {
                    _currentThemeMode = value;
                  });
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('暗色模式'),
              value: ThemeMode.dark,
              groupValue: _currentThemeMode,
              onChanged: (value) {
                if (value != null) {
                  widget.setThemeMode(value);
                  setState(() {
                    _currentThemeMode = value;
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showLyricsApiDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择歌词API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<LyricsApiType>(
              title: const Text('OpenSubsonic API'),
              subtitle: const Text('使用服务器返回的带时间轴歌词'),
              value: LyricsApiType.subsonic,
              groupValue: _currentLyricsApiType,
              onChanged: (value) {
                if (value != null) {
                  _saveLyricsApiType(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<LyricsApiType>(
              title: const Text('自定义API'),
              subtitle: const Text('使用自建的歌词API'),
              value: LyricsApiType.customApi,
              groupValue: _currentLyricsApiType,
              onChanged: (value) {
                if (value != null) {
                  _saveLyricsApiType(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
