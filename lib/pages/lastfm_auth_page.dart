import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/lastfm_api.dart';
import '../utils/lastfm_config.dart';

class LastFMAuthPage extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const LastFMAuthPage({
    super.key,
    required this.onAuthSuccess,
  });

  @override
  State<LastFMAuthPage> createState() => _LastFMAuthPageState();
}

class _LastFMAuthPageState extends State<LastFMAuthPage> {
  final LastFMApi _api = LastFMApi();
  bool _isLoading = false;
  bool _isAuthorizing = false;
  String? _authUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkIfConfigured();
  }

  Future<void> _checkIfConfigured() async {
    if (!LastFMConfig.isConfigured) {
      setState(() {
        _errorMessage = 'LastFM API未配置，请联系开发者';
      });
    }
  }

  Future<void> _startAuthorization() async {
    if (!LastFMConfig.isConfigured) {
      setState(() {
        _errorMessage = 'LastFM API未配置，请联系开发者';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _api.getAuthToken();
      final authUrl = 'https://www.last.fm/api/auth/?api_key=${LastFMConfig.apiKey}&token=$token';

      setState(() {
        _authUrl = authUrl;
        _isAuthorizing = true;
      });

      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        setState(() {
          _errorMessage = '无法打开浏览器，请手动访问授权链接';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '授权失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeAuthorization() async {
    if (_authUrl == null) {
      setState(() {
        _errorMessage = '请先开始授权流程';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
        final uri = Uri.parse(_authUrl!);
        final token = uri.queryParameters['token'];
        if (token == null) {
          throw Exception('无法从授权URL中提取token');
        }
        
        await _api.getSessionKey(token);
        widget.onAuthSuccess();
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _errorMessage = '完成授权失败: $e。请确保已在浏览器中完成授权。';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Last.fm 授权'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.audiotrack_rounded,
                    size: 80,
                    color: colorScheme.primary,
                  ),

                  const SizedBox(height: 24),

                  Text(
                    '连接 Last.fm',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '授权后可以查看您的听歌记录、顶级艺术家等数据',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  if (_errorMessage != null)
                    Card(
                      color: colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_errorMessage != null) const SizedBox(height: 24),

                  if (!_isAuthorizing)
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _startAuthorization,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.link_rounded),
                      label: Text(_isLoading ? '获取授权链接...' : '开始授权'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                  if (_isAuthorizing) ...[
                    Card(
                      color: colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '已在浏览器中打开授权页面',
                                    style: TextStyle(
                                      color: colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '请在浏览器中完成授权后，点击下方按钮完成授权流程',
                              style: TextStyle(
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    FilledButton.icon(
                      onPressed: _isLoading ? null : _completeAuthorization,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(_isLoading ? '完成授权...' : '我已完成授权'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isAuthorizing = false;
                          _authUrl = null;
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('重新开始'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  Text(
                    '授权后，您的听歌记录将自动同步到 Last.fm',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
