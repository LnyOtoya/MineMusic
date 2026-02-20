import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/player_service.dart';
import '../services/subsonic_api.dart';
import '../services/enhanced_color_manager_service.dart';
import '../services/lyrics_api.dart';
import '../models/lyrics_api_type.dart';
import '../utils/lrc_to_qrc_converter.dart';

class EnhancedPlayerPage extends StatefulWidget {
  final PlayerService playerService;
  final SubsonicApi api;

  const EnhancedPlayerPage({
    super.key,
    required this.playerService,
    required this.api,
  });

  @override
  State<EnhancedPlayerPage> createState() => _EnhancedPlayerPageState();
}

class _EnhancedPlayerPageState extends State<EnhancedPlayerPage>
    with TickerProviderStateMixin {
  late AnimationController _colorAnimationController;
  late Animation<Color?> _primaryColorAnimation;
  late Animation<Color?> _surfaceColorAnimation;
  
  bool _isInitialized = false;
  String? _currentSongId;
  ColorScheme? _previousColorScheme;

  final _colorManager = EnhancedColorManagerService();

  @override
  void initState() {
    super.initState();

    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _colorManager.addColorListener(_onColorChanged);

    _initializePlayerState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentScheme = Theme.of(context).colorScheme;

    _primaryColorAnimation = ColorTween(
      begin: _previousColorScheme?.primary ?? currentScheme.primary,
      end: currentScheme.primary,
    ).animate(_colorAnimationController);

    _surfaceColorAnimation = ColorTween(
      begin: _previousColorScheme?.surface ?? currentScheme.surface,
      end: currentScheme.surface,
    ).animate(_colorAnimationController);

    _previousColorScheme = currentScheme;
  }

  Future<void> _initializePlayerState() async {
    final currentSong = widget.playerService.currentSong;
    _currentSongId = currentSong?['id'];

    if (currentSong != null && currentSong['coverArt'] != null) {
      await _loadColorFromCover(currentSong);
    }

    widget.playerService.addListener(_onPlayerStateChanged);
    _isInitialized = true;
  }

  Future<void> _loadColorFromCover(Map<String, dynamic> song) async {
    final coverArtId = song['coverArt'];
    final coverArtUrl = widget.api.getCoverArtUrl(coverArtId);

    print('🎨 开始加载封面颜色...');
    print('   Cover ID: $coverArtId');

    await _colorManager.updateColorFromCover(
      coverArtId: coverArtId,
      coverArtUrl: coverArtUrl,
    );
  }

  void _onPlayerStateChanged() {
    final newSongId = widget.playerService.currentSong?['id'];

    if (newSongId != _currentSongId) {
      _currentSongId = newSongId;

      if (widget.playerService.currentSong != null &&
          widget.playerService.currentSong['coverArt'] != null) {
        _loadColorFromCover(widget.playerService.currentSong!);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _onColorChanged(ColorSchemePair colorPair) {
    if (!mounted) return;

    print('🎨 颜色方案已变化');
    print('   新种子颜色: ${colorPair.seedColor}');

    final currentScheme = Theme.of(context).colorScheme;

    _primaryColorAnimation = ColorTween(
      begin: _previousColorScheme?.primary ?? currentScheme.primary,
      end: colorPair.light.primary,
    ).animate(_colorAnimationController);

    _surfaceColorAnimation = ColorTween(
      begin: _previousColorScheme?.surface ?? currentScheme.surface,
      end: colorPair.light.surface,
    ).animate(_colorAnimationController);

    _previousColorScheme = colorPair.light;

    _colorAnimationController.forward(from: 0);

    setState(() {});
  }

  @override
  void dispose() {
    _colorAnimationController.dispose();
    _colorManager.removeColorListener(_onColorChanged);
    widget.playerService.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.playerService.currentSong;
    final colorScheme = Theme.of(context).colorScheme;
    final tonalSurface = _colorManager.getTonalSurface(
      Theme.of(context).brightness,
    );

    return Scaffold(
      backgroundColor: tonalSurface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(currentSong, colorScheme),
            ),
            _buildControls(currentSong, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            '正在播放',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              _showOptionsMenu();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic>? song, ColorScheme colorScheme) {
    if (song == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_rounded,
              size: 80,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '没有正在播放的歌曲',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildAlbumCover(song, colorScheme),
          const SizedBox(height: 32),
          _buildSongInfo(song, colorScheme),
          const SizedBox(height: 40),
          _buildProgressBar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildAlbumCover(Map<String, dynamic> song, ColorScheme colorScheme) {
    final coverUrl = song['coverArt'] != null
        ? widget.api.getCoverArtUrl(song['coverArt'])
        : null;

    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: coverUrl != null
              ? CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  width: 280,
                  height: 280,
                  placeholder: (context, url) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.album_rounded,
                      size: 80,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.album_rounded,
                      size: 80,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.album_rounded,
                    size: 80,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(Map<String, dynamic> song, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            song['title'] ?? '未知标题',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            song['artist'] ?? '未知艺术家',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            song['album'] ?? '未知专辑',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme colorScheme) {
    final position = widget.playerService.currentPosition ?? Duration.zero;
    final total = widget.playerService.totalDuration ?? Duration.zero;
    final progress = total.inMilliseconds > 0
        ? position.inMilliseconds / total.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.surfaceContainerHighest,
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: progress,
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (total.inMilliseconds * value).toInt(),
                );
                widget.playerService.seekTo(newPosition);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatDuration(total),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(Map<String, dynamic>? song, ColorScheme colorScheme) {
    final isPlaying = widget.playerService.isPlaying;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.skip_previous_rounded,
              color: colorScheme.onSurface,
            ),
            iconSize: 32,
            onPressed: widget.playerService.previousSong,
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: colorScheme.onPrimary,
              ),
              iconSize: 36,
              onPressed: widget.playerService.togglePlayPause,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.skip_next_rounded,
              color: colorScheme.onSurface,
            ),
            iconSize: 32,
            onPressed: widget.playerService.nextSong,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: const Text('播放列表'),
              onTap: () {
                Navigator.pop(context);
                _showPlaylist();
              },
            ),
            ListTile(
              leading: const Icon(Icons.lyrics_rounded),
              title: const Text('歌词'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaylist() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '播放列表',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.playerService.playlist.length} 首歌曲',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.playerService.playlist.length,
                  itemBuilder: (context, index) {
                    final song = widget.playerService.playlist[index];
                    final isCurrentSong =
                        widget.playerService.currentSong?['id'] == song['id'];

                    return ListTile(
                      leading: song['coverArt'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.music_note_rounded,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                      title: Text(
                        song['title'] ?? '未知歌曲',
                        style: TextStyle(
                          fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                          color: isCurrentSong
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        song['artist'] ?? '未知艺术家',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: isCurrentSong
                          ? Icon(
                              Icons.equalizer_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        widget.playerService.playSongAt(index);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
