import 'package:flutter/material.dart';

class MaterialYouTestPage extends StatelessWidget {
  const MaterialYouTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material You 测试'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 基础信息
          _buildInfoCard(context),
          const SizedBox(height: 20),
          
          // 主要颜色测试
          _buildColorTestSection(context, '主色调', [
            _ColorInfo('primary', colorScheme.primary, colorScheme.onPrimary),
            _ColorInfo('onPrimary', colorScheme.onPrimary, colorScheme.primary),
            _ColorInfo('primaryContainer', colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
            _ColorInfo('onPrimaryContainer', colorScheme.onPrimaryContainer, colorScheme.primaryContainer),
          ]),
          
          const SizedBox(height: 20),
          
          // 次要颜色测试
          _buildColorTestSection(context, '次要色调', [
            _ColorInfo('secondary', colorScheme.secondary, colorScheme.onSecondary),
            _ColorInfo('onSecondary', colorScheme.onSecondary, colorScheme.secondary),
            _ColorInfo('secondaryContainer', colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
            _ColorInfo('onSecondaryContainer', colorScheme.onSecondaryContainer, colorScheme.secondaryContainer),
          ]),
          
          const SizedBox(height: 20),
          
          // 第三颜色测试
          _buildColorTestSection(context, '第三色调', [
            _ColorInfo('tertiary', colorScheme.tertiary, colorScheme.onTertiary),
            _ColorInfo('onTertiary', colorScheme.onTertiary, colorScheme.tertiary),
            _ColorInfo('tertiaryContainer', colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
            _ColorInfo('onTertiaryContainer', colorScheme.onTertiaryContainer, colorScheme.tertiaryContainer),
          ]),
          
          const SizedBox(height: 20),
          
          // 表面颜色测试
          _buildColorTestSection(context, '表面色调', [
            _ColorInfo('surface', colorScheme.surface, colorScheme.onSurface),
            _ColorInfo('onSurface', colorScheme.onSurface, colorScheme.surface),
            _ColorInfo('surfaceVariant', colorScheme.surfaceVariant, colorScheme.onSurfaceVariant),
            _ColorInfo('onSurfaceVariant', colorScheme.onSurfaceVariant, colorScheme.surfaceVariant),
          ]),
          
          const SizedBox(height: 20),
          
          // 背景和错误颜色
          _buildColorTestSection(context, '背景和错误', [
            _ColorInfo('background', colorScheme.background, colorScheme.onBackground),
            _ColorInfo('onBackground', colorScheme.onBackground, colorScheme.background),
            _ColorInfo('error', colorScheme.error, colorScheme.onError),
            _ColorInfo('onError', colorScheme.onError, colorScheme.error),
          ]),
          
          const SizedBox(height: 20),
          
          // Material 3 组件测试
          _buildComponentTestSection(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'material_you_add_button',
        onPressed: () {},
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '主题信息',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text('亮度: ${Theme.of(context).brightness}'),
            Text('使用 Material 3: ${Theme.of(context).useMaterial3}'),
            Text('种子色: ${colorScheme.primary}'),
            Text('动态配色: ${_isDynamicColor(colorScheme.primary) ? "是" : "否"}'),
          ],
        ),
      ),
    );
  }

  Widget _buildColorTestSection(BuildContext context, String title, List<_ColorInfo> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2,
          ),
          itemCount: colors.length,
          itemBuilder: (context, index) {
            final colorInfo = colors[index];
            return Container(
              decoration: BoxDecoration(
                color: colorInfo.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  colorInfo.name,
                  style: TextStyle(
                    color: colorInfo.foregroundColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildComponentTestSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Material 3 组件测试',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        
        // 按钮测试
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('Elevated'),
            ),
            FilledButton(
              onPressed: () {},
              child: const Text('Filled'),
            ),
            FilledButton.tonal(
              onPressed: () {},
              child: const Text('Tonal'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Outlined'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Text'),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // 导航栏测试
        NavigationBar(
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: '首页'),
            NavigationDestination(icon: Icon(Icons.search), label: '搜索'),
            NavigationDestination(icon: Icon(Icons.library_music), label: '音乐库'),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // 卡片测试
        Card(
          child: ListTile(
            leading: Icon(Icons.album, color: colorScheme.primary),
            title: Text('测试卡片', style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text('这是一个 Material 3 卡片'),
            trailing: IconButton(
              icon: Icon(Icons.play_arrow, color: colorScheme.primary),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }

  bool _isDynamicColor(Color color) {
    // 简单的动态颜色检测逻辑
    // 动态颜色通常不会是纯色值
    final value = color.value;
    return value != Colors.blue.value && 
           value != const Color(0xFF2196F3).value;
  }
}

class _ColorInfo {
  final String name;
  final Color backgroundColor;
  final Color foregroundColor;

  _ColorInfo(this.name, this.backgroundColor, this.foregroundColor);
}