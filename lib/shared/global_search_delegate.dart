import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/search_result.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_detail_screen.dart';
import 'package:provider/provider.dart';

class GlobalSearchDelegate extends SearchDelegate {
  final String hintText;

  GlobalSearchDelegate({required this.hintText})
    : super(searchFieldLabel: hintText);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70, fontSize: 18),
        border: InputBorder.none,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: const TextStyle(
          color: Colors.white,
          fontSize: 18,
        ), // Search input text
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().length < 2) {
      return Container();
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final appConfigProvider = Provider.of<AppConfigProvider>(
      context,
      listen: false,
    );
    final locale = Localizations.localeOf(context).languageCode;
    final localizations = AppLocalizations.of(context)!;

    return FutureBuilder<List<SearchResult>>(
      future: appConfigProvider.searchContent(query, locale),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              localizations.noResultsFound,
              style: const TextStyle(fontSize: 18.0),
            ),
          );
        }

        final results = snapshot.data!;
        final theme = Theme.of(context);

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            final title = locale == 'mr' ? result.titleMr : result.titleEn;
            final deityName = locale == 'mr'
                ? result.deity.nameMr
                : result.deity.nameEn;

            return Card(
              elevation: theme.cardTheme.elevation,
              color: theme.cardTheme.color,
              shape: theme.cardTheme.shape,
              margin: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: ListTile(
                title: Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                subtitle: Text(deityName),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.primary,
                  size: 16.0,
                ),
                onTap: () {
                  final contentList = [
                    {
                      'title_mr': result.titleMr,
                      'title_en': result.titleEn,
                      'fileName': '',
                      'imagePath': result.imagePath,
                      'assetPath': result.textResourcePath,
                      'youtube_video_id': result.youtubeVideoId,
                    },
                  ];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContentDetailScreen(
                        deity: result.deity,
                        contentType: result.contentType,
                        contentList: contentList,
                        currentIndex: 0,
                        imagePath: result.imagePath,
                        assetPath: result.textResourcePath,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
