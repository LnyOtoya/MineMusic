import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/subsonic_api.dart';
import '../../services/player_service.dart';
import '../../pages/artist_detail_page.dart';
import '../../pages/detail_page.dart';

class DesktopSearchPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;
  final String initialQuery;

  const DesktopSearchPage({
    super.key,
    required this.api,
    required this.playerService,
    this.initialQuery = '',
  });

  @override
  State<DesktopSearchPage> createState() => _DesktopSearchPageState();
}

class _DesktopSearchPageState extends State<DesktopSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Map<String, List<Map<String, dynamic>>> _searchResults = {
    'artists': [],
    'albums': [],
    'songs': [],
  };
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) {
      _searchController.text = widget.initialQuery;
      _performSearch(widget.initialQuery);
    } else {
      _searchFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = {'artists': [], 'albums': [], 'songs': []};
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final results = await widget.api.search3(
      query: query,
      artistCount: 20,
      albumCount: 20,
      songCount: 50,
    );

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 32),
          if (_isSearching)
            const Center(child: CircularProgressIndicator())
          else if (_hasSearched)
            _buildSearchResults()
          else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: widget.initialQuery.isEmpty,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '搜索歌曲、专辑、艺人...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = {
                        'artists': [],
                        'albums': [],
                        'songs': [],
                      };
                      _hasSearched = false;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
        ),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        onSubmitted: (value) {
          _performSearch(value);
        },
        onChanged: (value) {
          if (value.isEmpty) {
            setState(() {
              _searchResults = {'artists': [], 'albums': [], 'songs': []};
              _hasSearched = false;
            });
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 120,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            '搜索音乐',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '输入关键词搜索歌曲、专辑或艺人',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final artists = _searchResults['artists'] ?? [];
    final albums = _searchResults['albums'] ?? [];
    final songs = _searchResults['songs'] ?? [];

    if (artists.isEmpty && albums.isEmpty && songs.isEmpty) {
      return _buildNoResults();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (artists.isNotEmpty) ...[
          _buildSectionHeader('艺术家', artists.length),
          const SizedBox(height: 16),
          _buildArtistsGrid(artists),
          const SizedBox(height: 48),
        ],
        if (albums.isNotEmpty) ...[
          _buildSectionHeader('专辑', albums.length),
          const SizedBox(height: 16),
          _buildAlbumsGrid(albums),
          const SizedBox(height: 48),
        ],
        if (songs.isNotEmpty) ...[
          _buildSectionHeader('歌曲', songs.length),
          const SizedBox(height: 16),
          _buildSongsGrid(songs),
        ],
      ],
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 120,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            '未找到结果',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '尝试其他关键词',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtistsGrid(List<Map<String, dynamic>> artists) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        return _buildArtistCard(artists[index]);
      },
    );
  }

  Widget _buildArtistCard(Map<String, dynamic> artist) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistDetailPage(
                api: widget.api,
                playerService: widget.playerService,
                artist: artist,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: artist['coverArt'] != null
                    ? CachedNetworkImage(
                        imageUrl: widget.api.getCoverArtUrl(artist['coverArt']),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist['name'] ?? '未知艺术家',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${artist['albumCount'] ?? 0} 张专辑',
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
      ),
    );
  }

  Widget _buildAlbumsGrid(List<Map<String, dynamic>> albums) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        return _buildAlbumCard(albums[index]);
      },
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(
                api: widget.api,
                playerService: widget.playerService,
                item: album,
                type: DetailType.album,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: album['coverArt'] != null
                    ? CachedNetworkImage(
                        imageUrl: widget.api.getCoverArtUrl(album['coverArt']),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.album_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.album_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.album_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album['name'] ?? '未知专辑',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    album['artist'] ?? '未知艺术家',
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
      ),
    );
  }

  Widget _buildSongsGrid(List<Map<String, dynamic>> songs) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1,
      ),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        return _buildSongCard(songs[index], songs);
      },
    );
  }

  Widget _buildSongCard(
    Map<String, dynamic> song,
    List<Map<String, dynamic>> playlist,
  ) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => widget.playerService.playSong(
          song,
          sourceType: 'search',
          playlist: playlist,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: song['coverArt'] != null
                    ? CachedNetworkImage(
                        imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.music_note_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.music_note_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.music_note_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song['title'] ?? '未知歌曲',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song['artist'] ?? '未知艺术家',
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
      ),
    );
  }
}
