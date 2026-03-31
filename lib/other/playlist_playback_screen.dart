import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/shared/cross_platform_youtube_player.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

enum PlaybackMode { reading, video }

class PlaylistPlaybackScreen extends StatefulWidget {
  final DeityConfig deity;
  final List<Map<String, String>> contentList;
  final int initialIndex;
  final String playlistName;
  final PlaybackMode mode;

  const PlaylistPlaybackScreen({
    super.key,
    required this.deity,
    required this.contentList,
    required this.initialIndex,
    required this.playlistName,
    required this.mode,
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

    final currentItem = widget.contentList[_currentIndex];
    final currentTitle = locale.languageCode == 'mr'
        ? (currentItem['title_mr'] ?? '')
        : (currentItem['title_en'] ?? '');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            if (_currentIndex > 0)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => _playIndex(_currentIndex - 1),
              )
            else
              const SizedBox(width: 48),
            Expanded(
              child: Text(
                currentTitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (_currentIndex < widget.contentList.length - 1)
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 20),
                onPressed: () => _playIndex(_currentIndex + 1),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
        actions: [
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) {
            if (widget.mode == PlaybackMode.reading) {
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: _buildTextPane(fontProvider, locale),
                ),
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: _buildListPane(theme, locale)),
                const VerticalDivider(width: 1),
                Expanded(flex: 3, child: _buildTextPane(fontProvider, locale)),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 3,
                  child: _buildYoutubePane(theme, locale, localizations),
                ),
              ],
            );
          } else {
            return _buildMobileLayout(
              theme,
              locale,
              localizations,
              fontProvider,
            );
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(
    ThemeData theme,
    Locale locale,
    AppLocalizations localizations,
    FontProvider fontProvider,
  ) {
    // If in Reading Mode, skip the Tabs and just show the text content
    if (widget.mode == PlaybackMode.reading) {
      return Column(
        children: [Expanded(child: _buildTextPane(fontProvider, locale))],
      );
    }

    // In Video Mode, show the player and the Playlist/Lyrics tabs
    return Column(
      children: [
        _buildYoutubePane(theme, locale, localizations, isMobile: true),
        Expanded(
          child: DefaultTabController(
            length: 2,
            initialIndex: 0,
            child: Column(
              children: [
                TabBar(
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.appColors.secondaryText,
                  indicatorColor: theme.colorScheme.primary,
                  tabs: const [
                    Tab(icon: Icon(Icons.queue_music), text: 'Playlist'),
                    Tab(icon: Icon(Icons.lyrics), text: 'Lyrics'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildListPane(theme, locale),
                      _buildTextPane(fontProvider, locale),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
          final title = locale.languageCode == 'mr'
              ? item['title_mr']
              : item['title_en'];
          final isPlaying = index == _currentIndex;

          return ListTile(
            selected: isPlaying,
            selectedTileColor: theme.appColors.primarySwatch.withValues(
              alpha: 0.15,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            leading: Icon(
              isPlaying ? Icons.play_circle_fill : Icons.queue_music,
              color: isPlaying ? theme.appColors.primarySwatch : theme.appColors.secondaryText,
            ),
            title: Text(
              title!,
              style: TextStyle(
                fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                color: isPlaying ? theme.appColors.primarySwatch[900] : null,
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

    final theme = Theme.of(context);
    final langCode = locale.languageCode;
    final text =
        _currentContentData!['content_$langCode'] ??
        _currentContentData!['content_en'] ??
        '';

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Sensitivity for swipes
        const int sensitivity = 8;
        if (details.primaryVelocity! > sensitivity) {
          // Swipe Right (Go to previous item)
          if (_currentIndex > 0) {
            _playIndex(_currentIndex - 1);
          }
        } else if (details.primaryVelocity! < -sensitivity) {
          // Swipe Left (Go to next item)
          if (_currentIndex < widget.contentList.length - 1) {
            _playIndex(_currentIndex + 1);
          }
        }
      },
      child: Container(
        color: theme.appColors.surface,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: fontProvider.marathiTextStyle.copyWith(
                    fontSize: _fontSize,
                    height: 1.6,
                  ),
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
                    backgroundColor: Theme.of(
                      context,
                    ).appColors.primarySwatch.withValues(alpha: 0.8),
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    onPressed: () => _changeFontSize(2.0),
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'reduceSizePlayback',
                    mini: true,
                    backgroundColor: theme.appColors.primarySwatch.withValues(alpha: 0.8),
                    foregroundColor: theme.colorScheme.onPrimary,
                    onPressed: () => _changeFontSize(-2.0),
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYoutubePane(
    ThemeData theme,
    Locale locale,
    AppLocalizations localizations, {
    bool isMobile = false,
  }) {
    if (_isLoadingContent) {
      return const Center(child: CircularProgressIndicator());
    }
    final videoId = _currentContentData?['youtube_video_id'] as String?;
    final title =
        _currentContentData?['title_${locale.languageCode}'] ??
        _currentContentData?['title_en'] ??
        'Aarti';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.mode == PlaybackMode.video) ...[
          if (videoId != null && videoId.isNotEmpty)
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: CrossPlatformYoutubePlayer(
                key: ValueKey(
                  videoId,
                ), // Ensure player rebuilds when video changes
                videoId: videoId,
                autoPlay: true,
                onEnded: _playNext,
              ),
            )
          else
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(child: Text('Video unavailable')),
              ),
            ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 16),
      ],
    );

    return Container(
      color: theme.colorScheme.surface,
      child: isMobile
          ? Padding(padding: const EdgeInsets.all(16.0), child: content)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: content,
            ),
    );
  }
}
