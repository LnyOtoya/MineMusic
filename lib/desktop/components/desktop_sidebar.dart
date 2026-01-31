import 'package:flutter/material.dart';
import '../../services/subsonic_api.dart';
import '../../services/player_service.dart';
import '../../pages/settings_page.dart';

class DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final SubsonicApi api;
  final PlayerService playerService;
  final Function(ThemeMode) setThemeMode;

  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.api,
    required this.playerService,
    required this.setThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildLogo(context),
          const SizedBox(height: 8),
          _buildNavigation(context),
          const Spacer(),
          _buildCurrentPlaying(context),
          const SizedBox(height: 8),
          _buildSettings(context),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.music_note_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'MineMusic',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _buildNavItem(
            context,
            icon: Icons.home_rounded,
            selectedIcon: Icons.home_rounded,
            label: '主页',
            index: 0,
          ),
          _buildNavItem(
            context,
            icon: Icons.search_rounded,
            selectedIcon: Icons.search_rounded,
            label: '搜索',
            index: 1,
          ),
          _buildNavItem(
            context,
            icon: Icons.library_music_rounded,
            selectedIcon: Icons.library_music_rounded,
            label: '音乐库',
            index: 2,
          ),
          _buildNavItem(
            context,
            icon: Icons.playlist_play_rounded,
            selectedIcon: Icons.playlist_play_rounded,
            label: '播放列表',
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        onTap: () => onDestinationSelected(index),
      ),
    );
  }

  Widget _buildCurrentPlaying(BuildContext context) {
    final currentSong = playerService.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: currentSong['coverArt'] != null
                  ? Image.network(
                      api.getCoverArtUrl(currentSong['coverArt']),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.music_note_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        );
                      },
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
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        leading: Icon(
          Icons.settings_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          '设置',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SettingsPage(
                api: api,
                playerService: playerService,
                setThemeMode: setThemeMode,
              ),
            ),
          );
        },
      ),
    );
  }
}
