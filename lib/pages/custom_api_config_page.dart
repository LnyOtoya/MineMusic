import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_lyrics_api_config.dart';
import '../models/lyrics_api_type.dart';
import '../services/custom_lyrics_api_service.dart';

class CustomApiConfigPage extends StatefulWidget {
  final Function()? onConfigChanged;
  final Function(LyricsApiType)? onLyricsApiTypeChanged;

  const CustomApiConfigPage({
    super.key,
    this.onConfigChanged,
    this.onLyricsApiTypeChanged,
  });

  @override
  State<CustomApiConfigPage> createState() => _CustomApiConfigPageState();
}

class _CustomApiConfigPageState extends State<CustomApiConfigPage> {
  Future<List<CustomLyricsApiConfig>> _apisFuture = Future.value([]);
  CustomLyricsApiConfig? _selectedApi;

  @override
  void initState() {
    super.initState();
    _loadApis();
  }

  Future<void> _loadApis() async {
    final apis = await CustomLyricsApiService.getCustomApis();
    final selected = await CustomLyricsApiService.getSelectedApi();
    setState(() {
      _apisFuture = Future.value(apis);
      _selectedApi = selected;
    });
  }

  Future<void> _refresh() async {
    CustomLyricsApiService.clearCache();
    await _loadApis();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('歌词API'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<CustomLyricsApiConfig>>(
              future: _apisFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 16),
                        Text('加载失败: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final apis = snapshot.data ?? [];

                if (apis.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.api_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '还没有自定义歌词API',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _showAddApiDialog,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('添加自定义API'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: apis.length + 1,
                    itemBuilder: (context, index) {
                      if (index == apis.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: FilledButton.icon(
                            onPressed: _showAddApiDialog,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('添加自定义API'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        );
                      }

                      final api = apis[index];
                      final isSelected = _selectedApi?.name == api.name;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              isSelected
                                  ? Icons.check_rounded
                                  : Icons.api_outlined,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(
                            api.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            api.baseUrl,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isSelected)
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle_outline_rounded,
                                  ),
                                  onPressed: () => _selectApi(api),
                                  tooltip: '使用此API',
                                ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditApiDialog(api);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmDialog(api);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 20),
                                        SizedBox(width: 12),
                                        Text('编辑'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text('删除'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _showApiDetailDialog(api),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddApiDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ApiEditPage()),
    );

    if (result == true) {
      await _refresh();
      widget.onConfigChanged?.call();
    }
  }

  Future<void> _showEditApiDialog(CustomLyricsApiConfig api) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ApiEditPage(api: api)),
    );

    if (result == true) {
      await _refresh();
      widget.onConfigChanged?.call();
    }
  }

  void _showApiDetailDialog(CustomLyricsApiConfig api) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(api.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('API名称', api.name),
              _buildDetailRow('基础URL', api.baseUrl),
              _buildDetailRow('搜索端点', api.searchEndpoint),
              _buildDetailRow('歌词端点', api.lyricEndpoint),
              _buildDetailRow('歌曲ID字段', api.songIdField),
              _buildDetailRow('歌名字段', api.titleField),
              _buildDetailRow('艺术家字段', api.artistField),
              _buildDetailRow('歌词字段', api.lyricField),
              _buildDetailRow('翻译字段', api.translationField),
              _buildDetailRow('成功响应码', api.successCode),
              _buildDetailRow('数据字段', api.dataField),
              _buildDetailRow('艺术家路径', api.artistPath),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Future<void> _selectApi(CustomLyricsApiConfig api) async {
    await CustomLyricsApiService.setSelectedApi(api);
    await _refresh();
    widget.onConfigChanged?.call();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lyricsApiType', LyricsApiType.customApi.name);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已选择: ${api.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmDialog(CustomLyricsApiConfig api) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${api.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CustomLyricsApiService.deleteCustomApi(api.name);
      await _refresh();
      widget.onConfigChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API已删除'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class ApiEditPage extends StatefulWidget {
  final CustomLyricsApiConfig? api;

  const ApiEditPage({super.key, this.api});

  @override
  State<ApiEditPage> createState() => _ApiEditPageState();
}

class _ApiEditPageState extends State<ApiEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _baseUrlController;
  late TextEditingController _searchEndpointController;
  late TextEditingController _lyricEndpointController;
  late TextEditingController _songIdFieldController;
  late TextEditingController _titleFieldController;
  late TextEditingController _artistFieldController;
  late TextEditingController _lyricFieldController;
  late TextEditingController _translationFieldController;
  late TextEditingController _successCodeController;
  late TextEditingController _dataFieldController;
  late TextEditingController _artistPathController;
  String _searchMethod = 'GET';
  String _lyricMethod = 'GET';

  @override
  void initState() {
    super.initState();
    final api = widget.api;

    _nameController = TextEditingController(text: api?.name ?? '');
    _baseUrlController = TextEditingController(text: api?.baseUrl ?? '');
    _searchEndpointController = TextEditingController(
      text: api?.searchEndpoint ?? '/search/search_by_type',
    );
    _lyricEndpointController = TextEditingController(
      text: api?.lyricEndpoint ?? '/lyric/get_lyric',
    );
    _songIdFieldController = TextEditingController(
      text: api?.songIdField ?? 'mid',
    );
    _titleFieldController = TextEditingController(
      text: api?.titleField ?? 'title',
    );
    _artistFieldController = TextEditingController(
      text: api?.artistField ?? 'artist',
    );
    _lyricFieldController = TextEditingController(
      text: api?.lyricField ?? 'lyric',
    );
    _translationFieldController = TextEditingController(
      text: api?.translationField ?? 'trans',
    );
    _successCodeController = TextEditingController(
      text: api?.successCode ?? '200',
    );
    _dataFieldController = TextEditingController(
      text: api?.dataField ?? 'data',
    );
    _artistPathController = TextEditingController(
      text: api?.artistPath ?? 'artist',
    );
    _searchMethod = api?.searchMethod ?? 'GET';
    _lyricMethod = api?.lyricMethod ?? 'GET';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _searchEndpointController.dispose();
    _lyricEndpointController.dispose();
    _songIdFieldController.dispose();
    _titleFieldController.dispose();
    _artistFieldController.dispose();
    _lyricFieldController.dispose();
    _translationFieldController.dispose();
    _successCodeController.dispose();
    _dataFieldController.dispose();
    _artistPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.api == null ? '添加API' : '编辑API'),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('基本信息', [
              _buildTextField(
                _nameController,
                'API名称',
                '例如: 我的歌词API',
                required: true,
              ),
              _buildTextField(
                _baseUrlController,
                '基础URL',
                '例如: http://192.168.31.215:4555',
                required: true,
              ),
            ]),
            _buildSection('搜索接口', [
              _buildTextField(
                _searchEndpointController,
                '搜索端点',
                '例如: /search/search_by_type',
                required: true,
              ),
              _buildDropdown(
                '请求方法',
                _searchMethod,
                ['GET', 'POST'],
                (value) => setState(() => _searchMethod = value),
              ),
            ]),
            _buildSection('歌词接口', [
              _buildTextField(
                _lyricEndpointController,
                '歌词端点',
                '例如: /lyric/get_lyric',
                required: true,
              ),
              _buildDropdown('请求方法', _lyricMethod, [
                'GET',
                'POST',
              ], (value) => setState(() => _lyricMethod = value)),
            ]),
            _buildSection('字段映射', [
              _buildTextField(
                _songIdFieldController,
                '歌曲ID字段',
                '例如: mid',
                required: true,
              ),
              _buildTextField(
                _titleFieldController,
                '歌名字段',
                '例如: title',
                required: true,
              ),
              _buildTextField(
                _artistFieldController,
                '艺术家字段',
                '例如: artist',
                required: true,
              ),
              _buildTextField(
                _artistPathController,
                '艺术家路径',
                '例如: singer[0].name',
                required: true,
              ),
              _buildTextField(
                _lyricFieldController,
                '歌词字段',
                '例如: lyric',
                required: true,
              ),
              _buildTextField(
                _translationFieldController,
                '翻译字段',
                '例如: trans',
                required: false,
              ),
            ]),
            _buildSection('响应配置', [
              _buildTextField(
                _successCodeController,
                '成功响应码',
                '例如: 200',
                required: true,
              ),
              _buildTextField(
                _dataFieldController,
                '数据字段',
                '例如: data',
                required: true,
              ),
            ]),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saveApi,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return '此项为必填';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }

  Future<void> _saveApi() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final api = CustomLyricsApiConfig(
      name: _nameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      searchEndpoint: _searchEndpointController.text.trim(),
      lyricEndpoint: _lyricEndpointController.text.trim(),
      searchMethod: _searchMethod,
      lyricMethod: _lyricMethod,
      songIdField: _songIdFieldController.text.trim(),
      titleField: _titleFieldController.text.trim(),
      artistField: _artistFieldController.text.trim(),
      lyricField: _lyricFieldController.text.trim(),
      translationField: _translationFieldController.text.trim(),
      successCode: _successCodeController.text.trim(),
      dataField: _dataFieldController.text.trim(),
      artistPath: _artistPathController.text.trim(),
    );

    try {
      if (widget.api == null) {
        await CustomLyricsApiService.addCustomApi(api);
      } else {
        await CustomLyricsApiService.updateCustomApi(api);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.api == null ? 'API已添加' : 'API已更新'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
