import 'package:flutter/material.dart';
import '../../services/player_service.dart';
import '../../services/subsonic_api.dart';
import '../../pages/player_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DesktopPlayerBar extends StatefulWidget {
  final PlayerService playerService;
  final SubsonicApi api;

  const DesktopPlayerBar({
    super.key,
    required this.playerService,
    required this.api,
  });

  @override
  State<DesktopPlayerBar> createState() => _DesktopPlayerBarState();
}

class _DesktopPlayerBarState extends State<DesktopPlayerBar> {
  double _currentSliderValue = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    widget.playerService.addListener(_onPlayerStateChanged);
  }

  @override
  void dispose() {
    widget.playerService.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (!_isDragging && mounted) {
      setState(() {
        final position = widget.playerService.currentPosition;
        final duration = widget.playerService.totalDuration;
        if (duration != null && duration.inMilliseconds > 0) {
          _currentSliderValue =
              position.inMilliseconds / duration.inMilliseconds;
        }
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.playerService.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [_buildProgressBar(), _buildControls(currentSong)],
      ),
    );
  }

  Widget _buildProgressBar() {
    final currentPosition = widget.playerService.currentPosition;
    final totalDuration = widget.playerService.totalDuration;

    return Container(
      height: 4,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
          activeTrackColor: Theme.of(context).colorScheme.primary,
          inactiveTrackColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
        ),
        child: Slider(
          value: _currentSliderValue,
          onChanged: (value) {
            setState(() {
              _isDragging = true;
              _currentSliderValue = value;
            });
          },
          onChangeEnd: (value) {
            setState(() {
              _isDragging = false;
            });
            final duration = widget.playerService.totalDuration;
            if (duration != null) {
              final position = Duration(
                milliseconds: (duration.inMilliseconds * value).toInt(),
              );
              widget.playerService.seekTo(position);
            }
          },
        ),
      ),
    );
  }

  Widget _buildControls(Map<String, dynamic> currentSong) {
    final currentPosition = widget.playerService.currentPosition;
    final totalDuration = widget.playerService.totalDuration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Left: Song info
          _buildSongInfo(currentSong),

          // Center: Playback controls and time display
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPlaybackControls(),
                const SizedBox(width: 24),
                _buildTimeDisplay(currentPosition, totalDuration),
              ],
            ),
          ),

          // Right: Volume controls and fullscreen button
          Row(
            children: [
              _buildVolumeControls(),
              const SizedBox(width: 16),
              _buildExtraControls(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongInfo(Map<String, dynamic> currentSong) {
    return SizedBox(
      width: 300,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: currentSong['coverArt'] != null
                  ? CachedNetworkImage(
                      imageUrl: widget.api.getCoverArtUrl(
                        currentSong['coverArt'],
                      ),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Icon(
                        Icons.music_note_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.music_note_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Icon(
                      Icons.music_note_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currentSong['title'] ?? '未知歌曲',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  currentSong['artist'] ?? '未知艺术家',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.favorite_border_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(
            Icons.skip_previous_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: 28,
          ),
          onPressed: widget.playerService.previousSong,
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              widget.playerService.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 28,
            ),
            onPressed: widget.playerService.togglePlayPause,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            Icons.skip_next_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: 28,
          ),
          onPressed: widget.playerService.nextSong,
        ),
        IconButton(
          icon: Icon(
            Icons.repeat_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildVolumeControls() {
    return SizedBox(
      width: 120,
      child: Row(
        children: [
          Icon(
            Icons.volume_up_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
              child: Slider(value: 0.7, onChanged: (value) {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(Duration? currentPosition, Duration? totalDuration) {
    return Text(
      '${_formatDuration(currentPosition ?? Duration.zero)} / ${_formatDuration(totalDuration ?? Duration.zero)}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildExtraControls() {
    return IconButton(
      icon: Icon(
        Icons.open_in_full_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerPage(
              playerService: widget.playerService,
              api: widget.api,
            ),
          ),
        );
      },
    );
  }
}
