import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/playlist_provider.dart';
import 'package:gajanan_maharaj_sevekari/other/playlist_playback_screen.dart';
import 'package:gajanan_maharaj_sevekari/shared/playlist_search_delegate.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';

class PlaylistDetailScreen extends StatefulWidget {
  const PlaylistDetailScreen({super.key});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late String playlistId;
  final Map<String, Map<String, dynamic>> _aartiDetailsCache = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    playlistId = ModalRoute.of(context)!.settings.arguments as String;
  }

  Future<void> _playPlaylist(
    BuildContext context,
    PlaylistProvider playlistProvider,
    int startIndex, {
    bool autoPlay = true,
  }) async {
    final playlist = playlistProvider.playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => playlistProvider.playlists.first,
    );

    if (playlist.aartiIds.isEmpty) return;

    // Load data for all items to construct content list
    final List<Map<String, String>> contentList = [];
    for (String path in playlist.aartiIds) {
      if (_aartiDetailsCache.containsKey(path)) {
        final data = _aartiDetailsCache[path]!;
        contentList.add(_buildContentMap(path, data));
      } else {
        try {
          final response = await rootBundle.loadString(path);
          final data = json.decode(response);
          _aartiDetailsCache[path] = data;
          contentList.add(_buildContentMap(path, data));
        } catch (e) {
          // Skip if missing
        }
      }
    }

    if (contentList.isEmpty) return;

    if (!context.mounted) return;

    final appConfigProvider = Provider.of<AppConfigProvider>(
      context,
      listen: false,
    );
    final defaultDeity = appConfigProvider.appConfig!.deities.first;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistPlaybackScreen(
          deity: defaultDeity,
          contentList: contentList,
          initialIndex: startIndex,
          playlistName: playlist.isDefault ? "My Favorites" : playlist.name,
          autoPlay: autoPlay,
        ),
      ),
    );
  }

  Map<String, String> _buildContentMap(String path, Map<String, dynamic> data) {
    return {
      'title_mr': data['title_mr'] ?? '',
      'title_en': data['title_en'] ?? '',
      'fileName': path.split('/').last,
      'imagePath':
          'resources/images/gajanan_maharaj/Gajanan_Maharaj.png', // Generic fallback
      'assetPath': path,
      'youtube_video_id': data['youtube_video_id'] ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        final playlist = playlistProvider.playlists.firstWhere(
          (p) => p.id == playlistId,
          orElse: () => playlistProvider.playlists.first,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              playlist.isDefault ? localizations.myFavorites : playlist.name,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: localizations.addAarti,
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: PlaylistSearchDelegate(
                      hintText: localizations.searchHint,
                      playlistId: playlist.id,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.home,
                  (route) => false,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.pushNamed(context, Routes.settings),
              ),
            ],
          ),
          body: playlist.aartiIds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.queue_music,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.nothingHereYet,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(localizations.addAarti),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          showSearch(
                            context: context,
                            delegate: PlaylistSearchDelegate(
                              hintText: localizations.searchHint,
                              playlistId: playlist.id,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow),
                              label: Text(localizations.playAll),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () =>
                                  _playPlaylist(context, playlistProvider, 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.menu_book),
                              label: Text(localizations.readAll),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () => _playPlaylist(
                                context,
                                playlistProvider,
                                0,
                                autoPlay: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: playlist.aartiIds.length,
                        onReorder: (oldIndex, newIndex) {
                          playlistProvider.reorderAartis(
                            playlist.id,
                            oldIndex,
                            newIndex,
                          );
                        },
                        itemBuilder: (context, index) {
                          final aartiId = playlist.aartiIds[index];

                          return FutureBuilder<String>(
                            key: ValueKey(aartiId),
                            future: rootBundle.loadString(aartiId),
                            builder: (context, snapshot) {
                              String title = aartiId
                                  .split('/')
                                  .last
                                  .replaceAll('.json', '');
                              if (snapshot.hasData) {
                                try {
                                  final data = json.decode(snapshot.data!);
                                  _aartiDetailsCache[aartiId] =
                                      data; // cache for fast playback
                                  title = locale.languageCode == 'mr'
                                      ? data['title_mr'] ?? title
                                      : data['title_en'] ?? title;
                                } catch (_) {}
                              }

                              return Card(
                                elevation: theme.cardTheme.elevation,
                                color: theme.cardTheme.color,
                                shape: theme.cardTheme.shape,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0,
                                  ),
                                  leading: ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(
                                      Icons.drag_handle,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.menu_book,
                                          color: Colors.orange,
                                        ),
                                        onPressed: () => _playPlaylist(
                                          context,
                                          playlistProvider,
                                          index,
                                          autoPlay: false,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.play_circle_outline,
                                          color: Colors.orange,
                                        ),
                                        onPressed: () => _playPlaylist(
                                          context,
                                          playlistProvider,
                                          index,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red,
                                        ),
                                        tooltip: localizations.removeAarti,
                                        onPressed: () {
                                          playlistProvider.removeAarti(
                                            playlist.id,
                                            aartiId,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () => _playPlaylist(
                                    context,
                                    playlistProvider,
                                    index,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
