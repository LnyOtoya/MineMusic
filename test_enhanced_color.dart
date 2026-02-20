import 'package:flutter/material.dart';
import 'services/enhanced_color_manager_service.dart';
import 'services/color/color_analyzer.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '增强取色系统测试',
      theme: ThemeData(
        colorScheme: EnhancedColorManagerService().lightScheme,
        useMaterial3: true,
      ),
      home: const TestHomePage(),
    );
  }
}

class TestHomePage extends StatefulWidget {
  const TestHomePage({super.key});

  @override
  State<TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<TestHomePage> {
  final _colorManager = EnhancedColorManagerService();

  @override
  void initState() {
    super.initState();

    _colorManager.addColorListener((colorPair) {
      print('颜色方案已更新: ${colorPair.seedColor}');
    });
  }

  @override
  void dispose() {
    _colorManager.removeColorListener((colorPair) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('增强取色系统测试'),
        backgroundColor: colorScheme.surface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.music_note_rounded,
                size: 80,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '当前种子颜色',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _colorManager.currentSeedColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _testColorAnalyzer();
              },
              child: const Text('测试颜色分析器'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _colorManager.clearCache();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('缓存已清除')),
                );
              },
              child: const Text('清除缓存'),
            ),
          ],
        ),
      ),
    );
  }

  void _testColorAnalyzer() {
    final testColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    for (final color in testColors) {
      final score = ColorAnalyzer.analyzeColor(color, 50);
      print('颜色: $color');
      print('  饱和度: ${score.saturation.toStringAsFixed(2)}');
      print('  亮度: ${score.brightness.toStringAsFixed(2)}');
      print('  突出度: ${score.prominence.toStringAsFixed(2)}');
      print('  总分: ${score.totalScore.toStringAsFixed(2)}');
      print('  是否中性色: ${ColorAnalyzer.isNeutralColor(color)}');
      print('  是否适合作为种子: ${ColorAnalyzer.isGoodSeedColor(color)}');
      print('');
    }
  }
}
