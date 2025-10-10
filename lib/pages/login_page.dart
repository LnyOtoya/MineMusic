import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subsonic_api.dart';

class LoginPage extends StatefulWidget {
  final Function(SubsonicApi, String, String, String) onLoginSuccess;

  const LoginPage({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // 加载保存的登录信息
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBaseUrl = prefs.getString('baseUrl');
      final savedUsername = prefs.getString('username');
      final savedPassword = prefs.getString('password');
      final savedRememberMe = prefs.getBool('rememberMe') ?? true;

      if (savedBaseUrl != null && savedUsername != null && savedPassword != null) {
        setState(() {
          _baseUrlController.text = savedBaseUrl;
          _usernameController.text = savedUsername;
          _passwordController.text = savedPassword;
          _rememberMe = savedRememberMe;
        });
      }
    } catch (e) {
      print('加载保存的凭据时出错: $e');
    }
  }

  // 保存登录信息
  Future<void> _saveCredentials() async {
    if (!_rememberMe) {
      // 如果不记住密码，则清除保存的信息
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('baseUrl');
      await prefs.remove('username');
      await prefs.remove('password');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseUrl', _baseUrlController.text.trim());
    await prefs.setString('username', _usernameController.text.trim());
    await prefs.setString('password', _passwordController.text);
    await prefs.setBool('rememberMe', _rememberMe);
  }

  // 验证并登录
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final baseUrl = _baseUrlController.text.trim();
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      // 创建 API 实例并测试连接
      final api = SubsonicApi(
        baseUrl: baseUrl,
        username: username,
        password: password,
      );

      // 测试 ping 连接
      final success = await api.ping();
      
      if (success) {
        // 保存凭据
        await _saveCredentials();
        
        // 调用回调函数
        widget.onLoginSuccess(api, baseUrl, username, password);
      } else {
        if (mounted) {
          _showErrorDialog('连接失败', '无法连接到服务器，请检查域名、端口和凭据是否正确。');
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 标题
              const Text(
                '音乐播放器',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '连接到 Navidrome',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),

              // 服务器地址输入
              TextFormField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: '服务器地址',
                  hintText: 'http://192.168.1.100:4533',
                  prefixIcon: Icon(Icons.dns),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入服务器地址';
                  }
                  if (!value.startsWith('http://') && !value.startsWith('https://')) {
                    return '请输入完整的URL（包含http://或https://）';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 用户名输入
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入用户名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 密码输入
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
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

              // 记住我选项
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
                  const Text('记住登录信息'),
                ],
              ),
              const SizedBox(height: 24),

              // 登录按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          '登录',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              // 帮助文本
              const SizedBox(height: 20),
              const Text(
                '请确保服务器地址格式正确，例如：http://your-domain.com:4533',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}