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
import 'package:url_launcher/url_launcher.dart';
import 'package:gajanan_maharaj_sevekari/shared/typo_report_dialog.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';

class StoryDetailScreen extends StatefulWidget {
  final DeityConfig deity;
  final List<Map<String, String>> contentList;
  final int currentIndex;
  final String assetPath;
  final String imagePath;
  final String storyType; // 'stories', 'audios', or 'videos'

  const StoryDetailScreen({
    super.key,
    required this.deity,
    required this.contentList,
    required this.currentIndex,
    required this.assetPath,
    required this.imagePath,
    required this.storyType,
  });

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  late Future<Map<String, dynamic>> _contentFuture;
  double _fontSize = 18.0;
  String _selectedText = '';
  String _deviceId = '';

  @override
  void initState() {
    super.initState();
    _contentFuture = _loadContent();
    _initDeviceId();
  }

  Future<void> _initDeviceId() async {
    final id = await UniqueIdService.getUniqueId();
    setState(() {
      _deviceId = id;
    });
  }

  void _showReportDialog(String typo, String title, String path) {
    showDialog(
      context: context,
      builder: (context) => TypoReportDialog(
        initialTypoText: typo,
        contentPath: path,
        contentTitle: title,
        contentType: widget.storyType,
        deityId: widget.deity.id,
        deviceId: _deviceId,
      ),
    );
  }

  Future<Map<String, dynamic>> _loadContent() async {
    final String response = await rootBundle.loadString(widget.assetPath);
    final data = await json.decode(response);
    return data;
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(10.0, 40.0);
    });
  }

  void _navigateToItem(int index) {
    final item = widget.contentList[index];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StoryDetailScreen(
          deity: widget.deity,
          contentList: widget.contentList,
          currentIndex: index,
          assetPath: item['assetPath']!,
          imagePath: item['imagePath']!,
          storyType: widget.storyType,
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
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Handle back arrow ourselves
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.currentIndex > 0)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => _navigateToItem(widget.currentIndex - 1),
              )
            else
              const SizedBox(width: 48), // Spacer to maintain alignment
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _contentFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final item = snapshot.data!;
                    final title =
                        item['title_${locale.languageCode}'] ??
                        item['title_en']!;
                    return Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            if (widget.currentIndex < widget.contentList.length - 1)
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => _navigateToItem(widget.currentIndex + 1),
              )
            else
              const SizedBox(width: 48), // Spacer to maintain alignment
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
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _contentFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  return _buildContent(snapshot.data!, locale, localizations);
                }
                return const Center(child: Text('No data'));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.storyType == 'stories'
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: _contentFuture,
                  builder: (context, snapshot) {
                    final title = snapshot.hasData
                        ? (snapshot.data!['title_${locale.languageCode}'] ??
                            snapshot.data!['title_en'] ??
                            '')
                        : '';
                    return FloatingActionButton(
                      heroTag: 'report',
                      mini: true,
                      backgroundColor: theme.appColors.primarySwatch.withValues(
                        alpha: 0.7,
                      ),
                      foregroundColor: theme.colorScheme.onPrimary,
                      tooltip: localizations.reportTypoTitle,
                      onPressed: () {
                        if (_selectedText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text(localizations.selectTextToReportHint),
                            ),
                          );
                        } else {
                          _showReportDialog(
                            _selectedText,
                            title,
                            widget.assetPath,
                          );
                        }
                      },
                      child: const Icon(Icons.flag_outlined, size: 20),
                    );
                  },
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'add',
                  mini: true,
                  backgroundColor: theme.appColors.primarySwatch.withValues(
                    alpha: 0.7,
                  ),
                  foregroundColor: theme.colorScheme.onPrimary,
                  onPressed: () => _changeFontSize(2.0),
                  child: const Icon(Icons.add, size: 20),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'remove',
                  mini: true,
                  backgroundColor: theme.appColors.primarySwatch.withValues(
                    alpha: 0.7,
                  ),
                  foregroundColor: theme.colorScheme.onPrimary,
                  onPressed: () => _changeFontSize(-2.0),
                  child: const Icon(Icons.remove, size: 20),
                ),
              ],
            )
          : null,
    );
  }

  // Navigation row was moved to AppBar

  Widget _buildContent(
    Map<String, dynamic> data,
    Locale locale,
    AppLocalizations localizations,
  ) {
    final title =
        data['title_${locale.languageCode}'] ?? data['title_en'] ?? '';
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary Title on top as a heading
          if (title.isNotEmpty) ...[
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 24),
          ],
          if (widget.storyType == 'videos' || widget.storyType == 'audios')
            _buildMediaContent(data, localizations)
          else
            _buildReadContent(data, locale),
        ],
      ),
    );
  }

  Widget _buildReadContent(Map<String, dynamic> data, Locale locale) {
    final fontProvider = Provider.of<FontProvider>(context);
    final text = data['content_${locale.languageCode}'] ?? data['content_en']!;
    final title =
        data['title_${locale.languageCode}'] ?? data['title_en'] ?? '';
    final localizations = AppLocalizations.of(context)!;

    return SelectableText(
      text,
      textAlign: TextAlign.left,
      style: fontProvider.marathiTextStyle.copyWith(
        fontSize: _fontSize,
        height: 1.6,
      ),
      onSelectionChanged: (selection, cause) {
        if (selection.start >= 0 &&
            selection.end <= text.length &&
            selection.start < selection.end) {
          _selectedText = text.substring(selection.start, selection.end);
        } else {
          _selectedText = '';
        }
      },
      contextMenuBuilder: (context, editableTextState) {
        final List<ContextMenuButtonItem> buttonItems =
            editableTextState.contextMenuButtonItems;
        buttonItems.insert(
          0,
          ContextMenuButtonItem(
            label: localizations.reportTypoTitle,
            onPressed: () {
              _showReportDialog(_selectedText, title, widget.assetPath);
              editableTextState.hideToolbar();
            },
          ),
        );
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: buttonItems,
        );
      },
    );
  }

  Widget _buildMediaContent(
    Map<String, dynamic> data,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);
    final videoUrl = data['youtube_url'] as String?;
    final legacyVideoId = data['youtube_video_id'] as String?;

    String? videoId;
    bool isShort = false;

    if (videoUrl != null && videoUrl.isNotEmpty) {
      isShort = videoUrl.contains('/shorts/');
      final uri = Uri.tryParse(videoUrl);
      if (uri != null) {
        if (isShort) {
          videoId = uri.pathSegments.last;
        } else if (uri.host.contains('youtube.com')) {
          videoId = uri.queryParameters['v'];
        } else if (uri.host.contains('youtu.be')) {
          videoId = uri.pathSegments.last;
        }
      }
    }

    // Fallback to legacy ID if URL parsing failed or URL was missing
    videoId ??= legacyVideoId;

    return Column(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AspectRatio(
            aspectRatio: isShort ? 9 / 16 : 16 / 9,
            child: videoId != null && videoId.isNotEmpty
                ? CrossPlatformYoutubePlayer(
                    videoId: videoId,
                    autoPlay: true,
                    onLaunchYoutube: () => _launchYoutube(videoId!),
                    onEnded: () {
                      if (widget.currentIndex < widget.contentList.length - 1) {
                        _navigateToItem(widget.currentIndex + 1);
                      }
                    },
                  )
                : Image.asset(widget.imagePath, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 24),
        if (widget.storyType == 'audios')
          Icon(Icons.audiotrack, size: 48, color: theme.colorScheme.primary),
      ],
    );
  }
}
