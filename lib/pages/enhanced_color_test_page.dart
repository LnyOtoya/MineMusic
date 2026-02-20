import 'package:flutter/material.dart';
import '../services/enhanced_color_manager_service.dart';
import '../services/color/enhanced_color_extractor_service.dart';
import '../services/color/color_analyzer.dart';

class EnhancedColorTestPage extends StatefulWidget {
  const EnhancedColorTestPage({super.key});

  @override
  State<EnhancedColorTestPage> createState() => _EnhancedColorTestPageState();
}

class _EnhancedColorTestPageState extends State<EnhancedColorTestPage> {
  final _colorManager = EnhancedColorManagerService();
  final _testImages = [
    {
      'name': '明亮封面',
      'url': 'https://picsum.photos/seed/bright/400/400',
      'description': '高饱和度、高亮度的封面',
    },
    {
      'name': '暗淡封面',
      'url': 'https://picsum.photos/seed/dark/400/400',
      'description': '低饱和度、低亮度的封面',
    },
    {
      'name': '中性色调',
      'url': 'https://picsum.photos/seed/neutral/400/400',
      'description': '中性色调为主的封面',
    },
    {
      'name': '高对比度',
      'url': 'https://picsum.photos/seed/contrast/400/400',
      'description': '高对比度的封面',
    },
    {
      'name': '单色图片',
      'url': 'https://picsum.photos/seed/mono/400/400',
      'description': '单色调的封面',
    },
  ];

  ColorExtractionResult? _currentResult;
  bool _isExtracting = false;

  @override
  void initState() {
    super.initState();

    _colorManager.addColorListener((colorPair) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _colorManager.removeColorListener((colorPair) {});
    super.dispose();
  }

  Future<void> _extractColor(String url) async {
    setState(() {
      _isExtracting = true;
      _currentResult = null;
    });

    try {
      final result = await EnhancedColorExtractorService.extractFromImage(
        imageUrl: url,
        brightness: Brightness.light,
      );

      setState(() {
        _currentResult = result;
        _isExtracting = false;
      });
    } catch (e) {
      setState(() {
        _isExtracting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提取失败: $e')),
        );
      }
    }
  }

  void _testColorAnalyzer(Color color) {
    final score = ColorAnalyzer.analyzeColor(color, 50);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('颜色分析结果'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildColorPreview(color),
            const SizedBox(height: 16),
            _buildScoreItem('饱和度评分', score.saturation),
            _buildScoreItem('亮度评分', score.brightness),
            _buildScoreItem('突出度评分', score.prominence),
            const SizedBox(height: 8),
            _buildScoreItem('总分', score.totalScore, isTotal: true),
            const SizedBox(height: 16),
            Text(
              '颜色属性',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildColorProperty('是否中性色', ColorAnalyzer.isNeutralColor(color)),
            _buildColorProperty('是否过亮', ColorAnalyzer.isTooBright(color)),
            _buildColorProperty('是否过暗', ColorAnalyzer.isTooDark(color)),
            _buildColorProperty('是否适合作为种子', ColorAnalyzer.isGoodSeedColor(color)),
          ],
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

  Widget _buildColorPreview(Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, double score, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            score.toStringAsFixed(2),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorProperty(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Icon(
            value ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: value
                ? Colors.green
                : Colors.red,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tonalSurface = _colorManager.getTonalSurface(Brightness.light);

    return Scaffold(
      appBar: AppBar(
        title: const Text('增强取色系统测试'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      backgroundColor: tonalSurface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentColorSection(colorScheme),
            const SizedBox(height: 24),
            _buildTestImagesSection(),
            const SizedBox(height: 24),
            if (_currentResult != null) _buildResultSection(colorScheme),
            const SizedBox(height: 24),
            _buildColorManagerSection(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentColorSection(ColorScheme colorScheme) {
    return Card(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前颜色方案',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildColorSwatch('Primary', colorScheme.primary),
                const SizedBox(width: 12),
                _buildColorSwatch('Secondary', colorScheme.secondary),
                const SizedBox(width: 12),
                _buildColorSwatch('Tertiary', colorScheme.tertiary),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildColorSwatch('Surface', colorScheme.surface),
                const SizedBox(width: 12),
                _buildColorSwatch('Primary Container', colorScheme.primaryContainer),
                const SizedBox(width: 12),
                _buildColorSwatch('Secondary Container', colorScheme.secondaryContainer),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildColorSwatch('On Surface', colorScheme.onSurface),
                const SizedBox(width: 12),
                _buildColorSwatch('On Primary', colorScheme.onPrimary),
                const SizedBox(width: 12),
                _buildColorSwatch('On Surface Variant', colorScheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '种子颜色: ${_colorManager.currentSeedColor}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTestImagesSection() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '测试图片',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._testImages.map((image) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildTestImageCard(image),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTestImageCard(Map<String, dynamic> image) {
    return InkWell(
      onTap: () => _extractColor(image['url'] as String),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                image['url'] as String,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image['name'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    image['description'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (_isExtracting)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.play_arrow_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(ColorScheme colorScheme) {
    return Card(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '提取结果',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildResultItem('种子颜色', _currentResult!.seedColor),
            _buildResultItem('主导颜色数量', '${_currentResult!.dominantColors.length}'),
            _buildResultItem('提取时间', _currentResult!.extractionTime),
            const SizedBox(height: 16),
            Text(
              '主导颜色',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _currentResult!.dominantColors.take(8).map((color) {
                return InkWell(
                  onTap: () => _testColorAnalyzer(color),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorManagerSection(ColorScheme colorScheme) {
    return Card(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '颜色管理器',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildManagerItem('是否有缓存', _colorManager.hasCachedScheme),
            _buildManagerItem('当前种子颜色', _colorManager.currentSeedColor),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () {
                      _colorManager.clearCache();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('缓存已清除')),
                      );
                    },
                    child: const Text('清除缓存'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _colorManager.clearCurrentColorScheme();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('颜色方案已重置')),
                      );
                    },
                    child: const Text('重置颜色'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
