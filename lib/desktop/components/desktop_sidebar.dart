import 'package:flutter/material.dart';
import '../../services/subsonic_api.dart';
import '../../services/player_service.dart';

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
          const SizedBox(height: 16),
          _buildNavigation(context),
          const Spacer(),
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
}
