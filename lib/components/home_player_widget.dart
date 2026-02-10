import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomePlayerWidget extends StatelessWidget {
  final String? coverUrl;
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onTap;

  const HomePlayerWidget({
    super.key,
    this.coverUrl,
    this.isPlaying = false,
    this.onPlayPause,
    this.onNext,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final containerSize = size.width * 0.7; // 70% of screen width

    return Center(
      child: SizedBox(
        width: containerSize,
        height: containerSize,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(containerSize / 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 圆形封面
              Hero(
                tag: 'home_album_cover',
                child: ClipOval(
                  child: Container(
                    width: containerSize,
                    height: containerSize,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(50),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: coverUrl!,
                            fit: BoxFit.cover,
                            placeholderFadeInDuration: Duration(milliseconds: 300),
                            fadeInDuration: Duration(milliseconds: 500),
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.music_note_outlined,
                                  size: containerSize * 0.3,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(
                                  Icons.music_note_outlined,
                                  size: containerSize * 0.3,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.music_note_outlined,
                                size: containerSize * 0.3,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              // 左下角播放/暂停按钮
              Positioned(
                bottom: -10,
                left: -10,
                child: Container(
                  width: containerSize * 0.3,
                  height: containerSize * 0.3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(30),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: 'play_pause_button',
                    onPressed: onPlayPause,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: containerSize * 0.15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),

              // 右上角下一曲按钮
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: containerSize * 0.25,
                  height: containerSize * 0.25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(30),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: 'next_button',
                    onPressed: onNext,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    shape: const CircleBorder(),
                    child: Icon(
                      Icons.skip_next_rounded,
                      size: containerSize * 0.12,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
