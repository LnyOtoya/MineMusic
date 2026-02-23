import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import 'login_page.dart';
import 'about_page.dart';

class SettingsPage extends StatefulWidget {
  final SubsonicApi? api;
  final PlayerService? playerService;
  final Function(ThemeMode)? setThemeMode;

  const SettingsPage({
    super.key,
    this.api,
    this.playerService,
    this.setThemeMode,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ThemeMode _currentThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
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

  @override
  void dispose() {
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
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          if (widget.api != null) _buildSection('账户', [
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('用户名'),
              subtitle: Text(widget.api!.username),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_rounded),
              title: const Text('服务器地址'),
              subtitle: Text(
                widget.api!.baseUrl,
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
          ]),
          const SizedBox(height: 16),
          _buildSection('其他', [
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('关于'),
              subtitle: const Text('MineMusic v1.2.3'),
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
                if (value != null && widget.setThemeMode != null) {
                  widget.setThemeMode!(value);
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
                if (value != null && widget.setThemeMode != null) {
                  widget.setThemeMode!(value);
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
                if (value != null && widget.setThemeMode != null) {
                  widget.setThemeMode!(value);
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
}
