import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/shared/global_search_delegate.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/providers/playlist_provider.dart';
import 'package:gajanan_maharaj_sevekari/widgets/add_to_playlist_modal.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_loading_indicator.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:provider/provider.dart';

class ContentListScreen extends StatefulWidget {
  final DeityConfig deity;
  final String title;
  final ContentType contentType;
  final ContentContainer content;

  const ContentListScreen({
    super.key,
    required this.deity,
    required this.title,
    required this.contentType,
    required this.content,
  });

  @override
  State<ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends State<ContentListScreen> {
  late Future<List<Map<String, String>>> _contentListFuture;

  @override
  void initState() {
    super.initState();
    _contentListFuture = _loadContentList();
  }

  Future<List<Map<String, String>>> _loadContentList() async {
    final List<Map<String, String>> contentList = [];
    final parentTextDir = widget.content.textResourceDirectory;
    final parentImageDir = widget.content.imageResourceDirectory;

    for (var i = 0; i < widget.content.files.length; i++) {
      final item = widget.content.files[i];

      // Use the item's specific directory if provided, otherwise fall back to the parent's.
      final textPath =
          '${item.textResourceDirectory ?? parentTextDir}/${item.file}';
      final imagePath =
          '${item.imageResourceDirectory ?? parentImageDir}/${item.image}';

      final String response = await rootBundle.loadString(textPath);
      final data = await json.decode(response);

      contentList.add({
        'title_mr': data['title_mr']!,
        'title_en': data['title_en']!,
        'fileName': item.file,
        'imagePath': imagePath,
        'assetPath': textPath,
        'youtube_video_id': data['youtube_video_id']!,
      });
    }
    return contentList;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final festivalProvider = Provider.of<FestivalProvider>(context);
    final isGaneshotsav = festivalProvider.activeFestival?.id == 'ganesh_chaturthi';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const ThemedIcon(LogicalIcon.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(
                  hintText: localizations.searchHint,
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
      body: FutureBuilder<List<Map<String, String>>>(
        future: _contentListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ThemedLoadingIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final items = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 100.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemTitle = locale.languageCode == 'mr'
                    ? item['title_mr']
                    : item['title_en'];

                return Card(
                  elevation: theme.cardTheme.elevation,
                  color: theme.cardTheme.color,
                  shape: theme.cardTheme.shape,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: widget.contentType == ContentType.granth
                        ? (isGaneshotsav
                            ? Image.asset(
                                'resources/images/festive_icons/ganesh_chaturthi/list.png',
                                width: 28,
                                height: 28,
                              )
                            : CircleAvatar(
                                backgroundColor: theme.appColors.primarySwatch[300],
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ))
                        : null,
                    title: Text(
                      itemTitle!,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Consumer<PlaylistProvider>(
                          builder: (context, playlistProvider, child) {
                            final assetPath = item['assetPath']!;
                            final isFavorite = playlistProvider.isFavorite(
                              assetPath,
                            );

                            return IconButton(
                              icon: isFavorite
                                  ? ThemedIcon(
                                      LogicalIcon.favorites,
                                      color: theme.colorScheme.primary,
                                    )
                                  : Icon(
                                      Icons.favorite_border,
                                      color: theme.colorScheme.primary,
                                    ),
                              onPressed: () async {
                                final playlists = playlistProvider.playlists;
                                if (playlists.length == 1) {
                                  final defaultPl = playlists.first;
                                  if (isFavorite) {
                                    await playlistProvider.removeAarti(
                                      defaultPl.id,
                                      assetPath,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            localizations.removedFromPlaylist,
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    await playlistProvider.addAarti(
                                      defaultPl.id,
                                      assetPath,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            localizations.addedToPlaylist,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  showAddToPlaylistModal(context, assetPath);
                                }
                              },
                            );
                          },
                        ),
                        if (item['youtube_video_id']!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.play_circle_outline),
                            color: theme.colorScheme.primary,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ContentDetailScreen(
                                    deity: widget.deity,
                                    contentType: widget.contentType,
                                    contentList: items,
                                    currentIndex: index,
                                    imagePath: item['imagePath']!,
                                    assetPath: item['assetPath']!,
                                    initialTabIndex: 1,
                                    autoPlay: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: theme.colorScheme.primary,
                          size: 16.0,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContentDetailScreen(
                            deity: widget.deity,
                            contentType: widget.contentType,
                            contentList: items,
                            currentIndex: index,
                            imagePath: item['imagePath']!,
                            assetPath: item['assetPath']!,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No items found'));
          }
        },
      ),
    );
  }
}
