import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AartiDetailScreen extends StatefulWidget {
  final List<Map<String, String>> aartiList;
  final int currentIndex;
  final int initialTabIndex;
  final bool autoPlay;

  const AartiDetailScreen({
    super.key,
    required this.aartiList,
    required this.currentIndex,
    this.initialTabIndex = 0,
    this.autoPlay = false,
  });

  @override
  State<AartiDetailScreen> createState() => _AartiDetailScreenState();
}

class _AartiDetailScreenState extends State<AartiDetailScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _aartiFuture;
  double _fontSize = 18.0;
  TabController? _tabController;
  int _currentIndex = 0;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _aartiFuture = _loadAarti();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _currentIndex = widget.initialTabIndex;
    _tabController!.addListener(() {
      if (mounted) {
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

  Future<Map<String, dynamic>> _loadAarti() async {
    final aarti = widget.aartiList[widget.currentIndex];
    final String response = await rootBundle.loadString('resources/texts/aartis/${aarti['directory']}/${aarti['fileName']}');
    final data = await json.decode(response);
    if (data['youtube_video_id'] != null && data['youtube_video_id'].isNotEmpty) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: data['youtube_video_id'],
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

  void _navigateToAarti(int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AartiDetailScreen(
          aartiList: widget.aartiList,
          currentIndex: index,
          initialTabIndex: _currentIndex,
          autoPlay: false,
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
                onPressed: () => _navigateToAarti(widget.currentIndex - 1),
              )
            else
              const SizedBox(width: 48), // Placeholder for alignment
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _aartiFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final aarti = snapshot.data!;
                    final title = locale.languageCode == 'mr' ? aarti['title_mr'] : aarti['title_en'];
                    return Text(title, textAlign: TextAlign.center, maxLines: 2);
                  } else {
                    return const Text(''); // Placeholder while loading
                  }
                },
              ),
            ),
            if (widget.currentIndex < widget.aartiList.length - 1)
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => _navigateToAarti(widget.currentIndex + 1),
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
            onPressed: () => _changeFontSize(2.0),
            child: const Icon(Icons.add, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'remove',
            mini: true,
            onPressed: () => _changeFontSize(-2.0),
            child: const Icon(Icons.remove, size: 20),
          ),
        ],
      )
          : null,
    );
  }

  Widget _buildSegmentedControl(BuildContext context, AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25.0),
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
              color: isSelected ? Colors.orange : Colors.grey[200]!,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (index == 0) // Read tab
                Icon(
                  Icons.library_music_outlined,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
              if (index == 0) const SizedBox(width: 8),
              if (index == 1) // Listen tab
                Icon(
                  Icons.play_arrow,
                  color: isSelected ? Colors.white : Colors.grey[600],
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
    return FutureBuilder<Map<String, dynamic>>(
      future: _aartiFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final aarti = snapshot.data!;
          final text = locale.languageCode == 'mr' ? aarti['aarti_mr'] : aarti['aarti_en'];
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: _fontSize),
              ),
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
        future: _aartiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final aartiData = snapshot.data!;
            final videoId = aartiData['youtube_video_id'];
            final title = locale.languageCode == 'mr' ? aartiData['title_mr'] : aartiData['title_en'];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAartiImage(context, aartiData),
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
                      child: _buildActionButton(context, Icons.share, localizations.share, () {
                        Share.share(
                            'Check out this aarti: https://www.youtube.com/watch?v=$videoId');
                      }),
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
          }
          return const Center(child: Text('No data'));
        });
  }

  Widget _buildAartiImage(BuildContext context, Map<String, dynamic> aartiData) {
    final theme = Theme.of(context);
    final imageName = aartiData['image'];
    final aarti = widget.aartiList[widget.currentIndex];
    final directory = aarti['directory'] ?? '';

    final imagePath = imageName != null && imageName.isNotEmpty
        ? 'resources/images/aartis/$directory/$imageName'
        : 'resources/images/aartis/default.jpg';

    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        imagePath,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'resources/images/aartis/default.jpg', // Consistent default
            width: double.infinity,
          );
        },
      ),
    );
  }

  Widget _buildDecorativeDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(Icons.spa, color: Colors.orange[200]),
        ),
        const Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onPressed) {
    final theme = Theme.of(context);
    return Column(
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
            icon: Icon(icon, color: theme.colorScheme.primary),
            onPressed: onPressed,
            iconSize: 32.0,
            padding: const EdgeInsets.all(16.0),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: theme.colorScheme.primary)),
      ],
    );
  }
}
