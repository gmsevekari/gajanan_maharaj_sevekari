import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/utils/locale_extensions.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/playlist_provider.dart';
import 'package:gajanan_maharaj_sevekari/other/favorite_item_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/shared/playlist_search_delegate.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

class FavoriteItemListScreen extends StatefulWidget {
  const FavoriteItemListScreen({super.key});

  @override
  State<FavoriteItemListScreen> createState() => _FavoriteItemListScreenState();
}

class _FavoriteItemListScreenState extends State<FavoriteItemListScreen> {
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
    PlaybackMode mode = PlaybackMode.video,
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
        builder: (context) => FavoriteItemDetailScreen(
          deity: defaultDeity,
          contentList: contentList,
          initialIndex: startIndex,
          playlistName: playlist.isDefault ? AppLocalizations.of(context)!.myFavorites : (Localizations.localeOf(context).useMarathiContent ? playlist.name_mr : playlist.name_en),
          mode: mode,
        ),
      ),
    );
  }

  Map<String, String> _buildContentMap(String path, Map<String, dynamic> data) {
    return {
      'title_mr': (data['title_mr']?.toString().isNotEmpty == true) ? data['title_mr'] : '',
      'title_en': (data['title_en']?.toString().isNotEmpty == true) ? data['title_en'] : '',
      'fileName': path.split('/').last,
      'imagePath':
          'resources/images/gajanan_maharaj/Gajanan_Maharaj.png', // Generic fallback
      'assetPath': path,
      'youtube_video_id': (data['youtube_video_id']?.toString().isNotEmpty == true) ? data['youtube_video_id'] : '',
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
              playlist.isDefault ? localizations.myFavorites : (locale.useMarathiContent ? playlist.name_mr : playlist.name_en),
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
                icon: const ThemedIcon(LogicalIcon.home),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.home,
                  (route) => false,
                ),
              ),
              IconButton(
                icon: const ThemedIcon(LogicalIcon.settings),
                onPressed: () => Navigator.pushNamed(context, Routes.settings),
              ),
            ],
          ),
          body: playlist.aartiIds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.queue_music,
                        size: 64,
                        color: theme.appColors.secondaryText,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.nothingHereYet,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: theme.appColors.secondaryText),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(localizations.addAarti),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
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

                          return _FavoriteListItemWidget(
                            key: ValueKey(aartiId),
                            aartiId: aartiId,
                            index: index,
                            locale: locale,
                            theme: theme,
                            localizations: localizations,
                            cache: _aartiDetailsCache,
                            onPlayPlaylist: (idx, {PlaybackMode mode = PlaybackMode.video}) => 
                                _playPlaylist(context, playlistProvider, idx, mode: mode),
                            onRemove: () => playlistProvider.removeAarti(playlist.id, aartiId),
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

class _FavoriteListItemWidget extends StatefulWidget {
  final String aartiId;
  final int index;
  final Locale locale;
  final ThemeData theme;
  final AppLocalizations localizations;
  final Map<String, Map<String, dynamic>> cache;
  final void Function(int, {PlaybackMode mode}) onPlayPlaylist;
  final VoidCallback onRemove;

  const _FavoriteListItemWidget({
    super.key,
    required this.aartiId,
    required this.index,
    required this.locale,
    required this.theme,
    required this.localizations,
    required this.cache,
    required this.onPlayPlaylist,
    required this.onRemove,
  });

  @override
  State<_FavoriteListItemWidget> createState() => _FavoriteListItemWidgetState();
}

class _FavoriteListItemWidgetState extends State<_FavoriteListItemWidget> {
  late Future<String> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = rootBundle.loadString(widget.aartiId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _contentFuture,
      builder: (context, snapshot) {
        String title = widget.aartiId.split('/').last.replaceAll('.json', '');
        if (snapshot.hasData) {
          try {
            final data = json.decode(snapshot.data!);
            widget.cache[widget.aartiId] = data; // cache for fast playback
            title = widget.locale.useMarathiContent
                ? ((data['title_mr']?.toString().isNotEmpty == true) ? data['title_mr'] : title)
                : ((data['title_en']?.toString().isNotEmpty == true) ? data['title_en'] : title);
          } catch (_) {}
        }

        return Card(
          elevation: widget.theme.cardTheme.elevation,
          color: widget.theme.cardTheme.color,
          shape: widget.theme.cardTheme.shape,
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
              index: widget.index,
              child: Icon(
                Icons.drag_handle,
                color: widget.theme.appColors.secondaryText,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.theme.colorScheme.onSurface,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.play_circle_outline,
                    color: widget.theme.appColors.primarySwatch,
                  ),
                  onPressed: () => widget.onPlayPlaylist(widget.index),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: widget.theme.appColors.error,
                  ),
                  tooltip: widget.localizations.removeAarti,
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            onTap: () => widget.onPlayPlaylist(
              widget.index,
              mode: PlaybackMode.reading,
            ),
          ),
        );
      },
    );
  }
}
