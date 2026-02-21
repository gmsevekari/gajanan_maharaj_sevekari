import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

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
      final textPath = '${item.textResourceDirectory ?? parentTextDir}/${item.file}';
      final imagePath = '${item.imageResourceDirectory ?? parentImageDir}/${item.image}';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _contentListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final items = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemTitle = locale.languageCode == 'mr' ? item['title_mr'] : item['title_en'];

                return Card(
                  elevation: theme.cardTheme.elevation,
                  color: theme.cardTheme.color,
                  shape: theme.cardTheme.shape,
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: widget.contentType == ContentType.granth
                        ? CircleAvatar(
                            backgroundColor: Colors.orange[300],
                            child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                          )
                        : null,
                    title: Text(
                      itemTitle!,
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18.0),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16.0),
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
