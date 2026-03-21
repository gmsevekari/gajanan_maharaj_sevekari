import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/shared/cross_platform_youtube_player.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';

class PlaylistPlaybackScreen extends StatefulWidget {
  final DeityConfig deity;
  final List<Map<String, String>> contentList;
  final int initialIndex;
  final String playlistName;

  const PlaylistPlaybackScreen({
    super.key,
    required this.deity,
    required this.contentList,
    required this.initialIndex,
    required this.playlistName,
  });

  @override
  State<PlaylistPlaybackScreen> createState() => _PlaylistPlaybackScreenState();
}

class _PlaylistPlaybackScreenState extends State<PlaylistPlaybackScreen> {
  int _currentIndex = 0;
  double _fontSize = 18.0;
  Map<String, dynamic>? _currentContentData;
  bool _isLoadingContent = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadCurrentContent();
  }

  Future<void> _loadCurrentContent() async {
    setState(() {
      _isLoadingContent = true;
    });
    try {
      final currentItem = widget.contentList[_currentIndex];
      final response = await rootBundle.loadString(currentItem['assetPath']!);
      final data = json.decode(response);
      setState(() {
        _currentContentData = data;
        _isLoadingContent = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingContent = false;
      });
    }
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(10.0, 40.0);
    });
  }

  void _playIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
    _loadCurrentContent();
  }

  void _playNext() {
    if (_currentIndex < widget.contentList.length - 1) {
      _playIndex(_currentIndex + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final localizations = AppLocalizations.of(context)!;
    final fontProvider = Provider.of<FontProvider>(context);

    // Responsive layout assumption: If it's phone portrait, we'll try our best 
    // or let it scroll horizontally, but since 3-pane is requested explicitly, 
    // we'll enforce the row structure. Best displayed in Chrome/Tablet.
    // If screen gets too small, flex deals with proportions.
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.playlistName} Playback'),
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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: _buildListPane(theme, locale),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 3,
            child: _buildTextPane(fontProvider, locale),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 3,
            child: _buildYoutubePane(theme, locale, localizations),
          ),
        ],
      ),
    );
  }

  Widget _buildListPane(ThemeData theme, Locale locale) {
    return Container(
      color: theme.colorScheme.surface,
      child: ListView.separated(
        itemCount: widget.contentList.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = widget.contentList[index];
          final title = locale.languageCode == 'mr' ? item['title_mr'] : item['title_en'];
          final isPlaying = index == _currentIndex;

          return ListTile(
            selected: isPlaying,
            selectedTileColor: Colors.orange.withValues(alpha: 0.15),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            leading: Icon(
              isPlaying ? Icons.play_circle_fill : Icons.queue_music,
              color: isPlaying ? Colors.orange : Colors.grey,
            ),
            title: Text(
              title!,
              style: TextStyle(
                fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                color: isPlaying ? Colors.orange[900] : null,
              ),
            ),
            onTap: () => _playIndex(index),
          );
        },
      ),
    );
  }

  Widget _buildTextPane(FontProvider fontProvider, Locale locale) {
    if (_isLoadingContent) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_currentContentData == null) {
      return const Center(child: Text('No content available.'));
    }

    final langCode = locale.languageCode;
    final text = _currentContentData!['content_$langCode'] ?? _currentContentData!['content_en'] ?? '';

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: fontProvider.marathiTextStyle.copyWith(fontSize: _fontSize, height: 1.6),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'addSizePlayback',
                  mini: true,
                  backgroundColor: Colors.orange.withValues(alpha: 0.8),
                  foregroundColor: Colors.white,
                  onPressed: () => _changeFontSize(2.0),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'reduceSizePlayback',
                  mini: true,
                  backgroundColor: Colors.orange.withValues(alpha: 0.8),
                  foregroundColor: Colors.white,
                  onPressed: () => _changeFontSize(-2.0),
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYoutubePane(ThemeData theme, Locale locale, AppLocalizations localizations) {
    if (_isLoadingContent) {
      return const Center(child: CircularProgressIndicator());
    }
    final videoId = _currentContentData?['youtube_video_id'] as String?;
    final title = _currentContentData?['title_${locale.languageCode}'] ?? _currentContentData?['title_en'] ?? 'Aarti';

    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (videoId != null && videoId.isNotEmpty)
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                clipBehavior: Clip.antiAlias,
                child: CrossPlatformYoutubePlayer(
                  key: ValueKey(videoId), // Ensure player rebuilds when video changes
                  videoId: videoId,
                  autoPlay: true,
                  onEnded: _playNext,
                )
              )
            else
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: const SizedBox(
                  height: 200,
                  child: Center(child: Text('Video unavailable')),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 48),
                  color: _currentIndex > 0 ? Colors.orange : Colors.grey,
                  tooltip: 'Previous Aarti',
                  onPressed: _currentIndex > 0 ? () => _playIndex(_currentIndex - 1) : null,
                ),
                const SizedBox(width: 48),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 48),
                  color: _currentIndex < widget.contentList.length - 1 ? Colors.orange : Colors.grey,
                  tooltip: 'Next Aarti',
                  onPressed: _currentIndex < widget.contentList.length - 1 ? _playNext : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
