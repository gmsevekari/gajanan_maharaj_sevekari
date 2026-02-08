import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

enum ContentType { granth, aarti, bhajan, stotra, namavali }

extension ContentTypeExtension on ContentType {
  static ContentType fromString(String contentType) {
    switch (contentType) {
      case 'granth':
        return ContentType.granth;
      case 'stotra':
        return ContentType.stotra;
      case 'bhajan':
        return ContentType.bhajan;
      case 'aarti':
        return ContentType.aarti;
      case 'namavali':
        return ContentType.namavali;
      default:
        return ContentType.granth;
    }
  }
}

class ContentDetailScreen extends StatefulWidget {
  final DeityConfig deity;
  final ContentType contentType;
  final List<Map<String, String>> contentList;
  final int currentIndex;
  final String assetPath;
  final int initialTabIndex;
  final bool autoPlay;
  final String imagePath;

  const ContentDetailScreen({
    super.key,
    required this.deity,
    required this.contentType,
    required this.contentList,
    required this.currentIndex,
    required this.assetPath,
    required this.imagePath,
    this.initialTabIndex = 0,
    this.autoPlay = false,
  });

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _contentFuture;
  double _fontSize = 18.0;
  TabController? _tabController;
  int _currentIndex = 0;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _contentFuture = _loadContent();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _currentIndex = widget.initialTabIndex;
    _tabController!.addListener(() {
      if (mounted && _tabController!.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController!.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadContent() async {
    final String response = await rootBundle.loadString(widget.assetPath);
    final data = await json.decode(response);
    final videoId = data['youtube_video_id'];
    if (videoId != null && videoId.isNotEmpty) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay,
        ),
      );
    }
    return data;
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(10.0, 40.0);
    });
  }

  void _navigateToItem(int index) {
    final item = widget.contentList[index];
    final newAssetPath = item['assetPath']!;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(
          deity: widget.deity,
          contentType: widget.contentType,
          contentList: widget.contentList,
          currentIndex: index,
          assetPath: newAssetPath,
          initialTabIndex: _currentIndex,
          autoPlay: false,
          imagePath: widget.contentList[index]['imagePath']!,
        ),
      ),
    );
  }

  Future<void> _launchYoutube(String videoId) async {
    final Uri url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Could not launch URL
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // We will handle navigation manually
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.currentIndex > 0)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => _navigateToItem(widget.currentIndex - 1),
              )
            else
              const SizedBox(width: 48), // Placeholder for alignment
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _contentFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final item = snapshot.data!;
                    final title = item['title_${locale.languageCode}'] ?? item['title_en']!;
                    return Text(title, textAlign: TextAlign.center, maxLines: 2,);
                  } else {
                    return const Text(''); // Placeholder while loading
                  }
                },
              ),
            ),
            if (widget.currentIndex < widget.contentList.length - 1)
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => _navigateToItem(widget.currentIndex + 1),
              )
            else
              const SizedBox(width: 48), // Placeholder for alignment
          ],
        ),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: _buildSegmentedControl(context, localizations),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildReadTab(locale),
                _buildListenTab(context, locale, localizations),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            mini: true,
            backgroundColor: Colors.orange.withAlpha(179),
            foregroundColor: Colors.white,
            onPressed: () => _changeFontSize(2.0),
            child: const Icon(Icons.add, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'remove',
            mini: true,
            backgroundColor: Colors.orange.withAlpha(179),
            foregroundColor: Colors.white,
            onPressed: () => _changeFontSize(-2.0),
            child: const Icon(Icons.remove, size: 20),
          ),
        ],
      )
          : null,
    );
  }

  Widget _buildSegmentedControl(
      BuildContext context, AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25.0),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSegment(context, localizations.read, 0),
          _buildSegment(context, localizations.listen, 1),
        ],
      ),
    );
  }

  Widget _buildSegment(BuildContext context, String text, int index) {
    bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController?.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.white,
            borderRadius: BorderRadius.circular(25.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (index == 0) // Read tab
                Icon(
                  Icons.queue_music,
                  color: isSelected ? Colors.white : Colors.grey[700],
                  size: 20,
                ),
              if (index == 0) const SizedBox(width: 8),
              if (index == 1) // Listen tab
                Icon(
                  Icons.play_arrow,
                  color: isSelected ? Colors.white : Colors.grey[700],
                  size: 20,
                ),
              if (index == 1) const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadTab(Locale locale) {
    final fontProvider = Provider.of<FontProvider>(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _contentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          final langCode = locale.languageCode;
          final text = data['content_$langCode'] ?? data['content_en']!;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: fontProvider.marathiTextStyle.copyWith(fontSize: _fontSize, height: 1.6),
            ),
          );
        } else {
          return const Center(child: Text('No data'));
        }
      },
    );
  }

  Widget _buildListenTab(BuildContext context, Locale locale, AppLocalizations localizations) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            final videoId = data['youtube_video_id'];
            final title = data['title_${locale.languageCode}'] ?? data['title_en']!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    elevation: theme.cardTheme.elevation,
                    shape: theme.cardTheme.shape,
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      widget.imagePath,
                      fit: BoxFit.cover, // Ensures the image covers the card area
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'resources/images/gajanan_maharaj/default.jpg', // A generic default
                          fit: BoxFit.cover, // Also apply fit to the error image
                          width: double.infinity,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_youtubeController != null)
                    Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        clipBehavior: Clip.antiAlias,
                        child: YoutubePlayer(
                          controller: _youtubeController!,
                          bottomActions: [
                            CurrentPosition(),
                            ProgressBar(isExpanded: true),
                            RemainingDuration(),
                            PlaybackSpeedButton(),
                            IconButton(
                              icon: const Icon(Icons.open_in_new, color: Colors.white),
                              onPressed: () => _launchYoutube(videoId),
                            ),
                          ],
                        ))
                  else
                    Card(
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      child: const SizedBox(
                        height: 200,
                        child: Center(child: Text('Video unavailable')),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDecorativeDivider(),
                  const SizedBox(height: 24),
                  if (videoId != null && videoId.isNotEmpty)
                    Center(
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.share, color: theme.colorScheme.primary),
                              onPressed: () {
                                Share.share(
                                    'Check out this content: https://www.youtube.com/watch?v=$videoId');
                              },
                              iconSize: 32.0,
                              padding: const EdgeInsets.all(16.0),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(localizations.share, style: TextStyle(color: theme.colorScheme.primary)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi, color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          localizations.internetRequired,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        });
  }

  Widget _buildDecorativeDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(height: 1, width: 50, color: Colors.orange[200]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Icon(Icons.music_note, color: Colors.orange[400]),
        ),
        Container(height: 1, width: 50, color: Colors.orange[200]),
      ],
    );
  }
}
