import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subsonic_api.dart';

class LoginPage extends StatefulWidget {
  final Function(SubsonicApi, String, String, String) onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _portController = TextEditingController(text: '4533');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBaseUrl = prefs.getString('baseUrl');
      final savedUsername = prefs.getString('username');
      final savedPassword = prefs.getString('password');
      final savedRememberMe = prefs.getBool('rememberMe') ?? true;

      if (savedBaseUrl != null &&
          savedUsername != null &&
          savedPassword != null) {
        final uri = Uri.parse(savedBaseUrl);
        setState(() {
          _baseUrlController.text = '${uri.scheme}://${uri.host}';
          _portController.text = uri.port.toString();
          _usernameController.text = savedUsername;
          _passwordController.text = savedPassword;
          _rememberMe = savedRememberMe;
        });
      }
    } catch (e) {
      print('加载保存的凭据时出错: $e');
    }
  }

  Future<void> _saveCredentials() async {
    if (!_rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('baseUrl');
      await prefs.remove('username');
      await prefs.remove('password');
      return;
    }

    final baseUrl = _buildBaseUrl();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseUrl', baseUrl);
    await prefs.setString('username', _usernameController.text.trim());
    await prefs.setString('password', _passwordController.text);
    await prefs.setBool('rememberMe', _rememberMe);
  }

  String _buildBaseUrl() {
    final scheme = _baseUrlController.text.startsWith('https')
        ? 'https'
        : 'http';
    final host = _baseUrlController.text
        .replaceFirst('http://', '')
        .replaceFirst('https://', '')
        .trim();
    final port = _portController.text.trim();
    return '$scheme://$host:$port';
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final baseUrl = _buildBaseUrl();
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      final api = SubsonicApi(
        baseUrl: baseUrl,
        username: username,
        password: password,
      );

      final success = await api.ping();

      if (success) {
        await _saveCredentials();
        widget.onLoginSuccess(api, baseUrl, username, password);
      } else {
        if (mounted) {
          _showErrorDialog('连接失败', '无法连接到服务器，请检查地址、端口和凭据是否正确。');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('登录失败', '错误: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    Icon(
                      Icons.music_note_rounded,
                      size: 60,
                      color: colorScheme.primary,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'MineMusic',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '连接到 Navidrome 服务器',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '服务器信息',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _baseUrlController,
                                    decoration: InputDecoration(
                                      labelText: '地址',
                                      hintText: '192.168.1.100',
                                      prefixIcon: const Icon(Icons.dns_rounded),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: colorScheme.surface,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '请输入服务器地址';
                                      }
                                      return null;
                                    },
                                  ),
                                ),

                                const SizedBox(width: 12),

                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: _portController,
                                    decoration: InputDecoration(
                                      labelText: '端口',
                                      hintText: '4533',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: colorScheme.surface,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 16,
                                          ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '请输入端口';
                                      }
                                      final port = int.tryParse(value);
                                      if (port == null ||
                                          port < 1 ||
                                          port > 65535) {
                                        return '无效端口';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: '用户名',
                                hintText: '输入用户名',
                                prefixIcon: const Icon(Icons.person_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: colorScheme.surface,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入用户名';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: '密码',
                                hintText: '输入密码',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: colorScheme.surface,
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入密码';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? true;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    '记住登录信息',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    FilledButton.tonalIcon(
                      onPressed: _isLoading ? null : _login,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.login_rounded),
                      label: Text(
                        _isLoading ? '连接中...' : '登录',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.folder_rounded),
                      label: const Text('本地访问', style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      '提示：确保服务器地址格式正确，例如：192.168.1.100',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
