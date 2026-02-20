import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import '../models/lyrics_model.dart';

class LyricsWidget extends StatefulWidget {
  final LyricsData? lyricsData;
  final Duration currentPosition;
  final bool isPlaying;

  const LyricsWidget({
    super.key,
    required this.lyricsData,
    required this.currentPosition,
    required this.isPlaying,
  });

  @override
  State<LyricsWidget> createState() => _LyricsWidgetState();
}

class _LyricsWidgetState extends State<LyricsWidget> {
  late LyricController _lyricController;

  @override
  void initState() {
    super.initState();
    _lyricController = LyricController();
    _loadLyrics();
  }

  @override
  void didUpdateWidget(LyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lyricsData?.toString() != widget.lyricsData?.toString()) {
      _loadLyrics();
    }
    _lyricController.setProgress(widget.currentPosition);
  }

  void _loadLyrics() {
    if (widget.lyricsData == null || widget.lyricsData!.isEmpty) {
      _lyricController.loadLyric('');
      return;
    }

    final lrcString = _convertToLrcFormat();
    _lyricController.loadLyric(lrcString);
    _lyricController.setProgress(widget.currentPosition);
  }

  String _convertToLrcFormat() {
    final buffer = StringBuffer();
    for (final line in widget.lyricsData!.lines) {
      final minutes = line.startTime ~/ 60000;
      final seconds = (line.startTime % 60000) ~/ 1000;
      final milliseconds = line.startTime % 1000;
      final timeTag = '[${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}]';
      buffer.writeln('$timeTag${line.text}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lyricsData == null) {
      return _buildLoadingState();
    }

    if (widget.lyricsData!.isEmpty) {
      return _buildEmptyState();
    }

    return _buildLyricsContent();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '加载歌词中...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无歌词',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Row(
            children: [
              Text(
                '歌词',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (widget.lyricsData!.lang != 'und')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.lyricsData!.languageName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: LyricView(
            controller: _lyricController,
            style: _createLyricStyle(),
          ),
        ),
      ],
    );
  }

  LyricStyle _createLyricStyle() {
    return LyricStyle(
      textStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 18,
        height: 1.6,
      ),
      activeStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        height: 1.6,
      ),
      lineGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      activeAnchorPosition: 0.5,
      activeAlignment: MainAxisAlignment.center,
      fadeRange: FadeRange(
        top: 0.1,
        bottom: 0.9,
      ),
      scrollDuration: const Duration(milliseconds: 300),
      scrollCurve: Curves.easeInOut,
      lineTextAlign: TextAlign.center,
      contentAlignment: CrossAxisAlignment.center,
      selectionAlignment: MainAxisAlignment.center,
      selectionAnchorPosition: 0.5,
      selectionAutoResumeDuration: const Duration(seconds: 2),
      activeAutoResumeDuration: const Duration(seconds: 3),
      translationLineGap: 4,
      translationStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        fontSize: 14,
      ),
      selectedColor: Theme.of(context).colorScheme.primary,
      selectedTranslationColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
    );
  }

  @override
  void dispose() {
    _lyricController.dispose();
    super.dispose();
  }
}
