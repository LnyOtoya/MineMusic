import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import '../widgets/material_wave_slider.dart';
import '../widgets/stateful_page_view_builder.dart';

class PlaybackPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;

  const PlaybackPage({
    super.key,
    required this.api,
    required this.playerService,
  });

  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
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
    if (mounted) {
      setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _onPageChanged(int index) {
    if (index != widget.playerService.currentIndex) {
      widget.playerService.playSongAt(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.playerService.currentSong;
    final isPlaying = widget.playerService.isPlaying;
    final currentPosition = widget.playerService.currentPosition;
    final totalDuration = widget.playerService.totalDuration;
    final currentIndex = widget.playerService.currentIndex;
    final playlist = widget.playerService.currentPlaylist;

    final progress = totalDuration.inMilliseconds > 0
        ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('播放'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surfaceContainerLow,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            const Spacer(flex: 1),

            Expanded(
              flex: 4,
              child: StatefulPageViewBuilder(
                index: currentIndex,
                itemCount: playlist.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: _onPageChanged,
                itemBuilder: (context, i) {
                  final song = playlist[i];
                  return Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: song['coverArt'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: CachedNetworkImage(
                              imageUrl: widget.api.getCoverArtUrl(
                                song['coverArt'],
                              ),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  size: 120,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  size: 120,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 120,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(
                    currentSong?['title'] ?? '未在播放',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentSong?['artist'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(currentPosition),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        _formatDuration(totalDuration),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MaterialWaveSlider(
                    height: 48.0,
                    value: progress,
                    min: 0.0,
                    max: 1.0,
                    paused: !isPlaying,
                    onChanged: (value) {
                      if (totalDuration.inMilliseconds > 0) {
                        final newPosition = Duration(
                          milliseconds: (value * totalDuration.inMilliseconds).round(),
                        );
                        widget.playerService.seekTo(newPosition);
                      }
                    },
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
