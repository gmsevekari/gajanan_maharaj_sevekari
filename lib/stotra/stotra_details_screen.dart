import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class StotraDetailsScreen extends StatefulWidget {
  final List<Map<String, String>> stotraList;
  final int currentIndex;
  final int initialTabIndex;
  final bool autoPlay;

  const StotraDetailsScreen({
    super.key,
    required this.stotraList,
    required this.currentIndex,
    this.initialTabIndex = 0,
    this.autoPlay = false,
  });

  @override
  State<StotraDetailsScreen> createState() => _StotraDetailsScreenState();
}

class _StotraDetailsScreenState extends State<StotraDetailsScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _stotraFuture;
  double _fontSize = 18.0;
  TabController? _tabController;
  int _currentIndex = 0;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _stotraFuture = _loadStotra();
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

  Future<Map<String, dynamic>> _loadStotra() async {
    final stotra = widget.stotraList[widget.currentIndex];
    final directory = stotra['directory'] ?? '';
    final path = directory.isNotEmpty
        ? 'resources/texts/stotras/$directory/${stotra['fileName']}'
        : 'resources/texts/stotras/${stotra['fileName']}';
    final String response = await rootBundle.loadString(path);
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

  void _navigateToStotra(int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StotraDetailsScreen(
          stotraList: widget.stotraList,
          currentIndex: index,
          initialTabIndex: _currentIndex,
          autoPlay: false, // Always disable autoplay on navigation
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
                onPressed: () => _navigateToStotra(widget.currentIndex - 1),
              )
            else
              const SizedBox(width: 48), // Placeholder for alignment
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _stotraFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final stotra = snapshot.data!;
                    final title = locale.languageCode == 'mr' ? stotra['title_mr'] : stotra['title_en'];
                    return Text(title, textAlign: TextAlign.center, maxLines: 2,);
                  } else {
                    return const Text(''); // Placeholder while loading
                  }
                },
              ),
            ),
            if (widget.currentIndex < widget.stotraList.length - 1)
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => _navigateToStotra(widget.currentIndex + 1),
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
    return FutureBuilder<Map<String, dynamic>>(
      future: _stotraFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final stotra = snapshot.data!;
          final text =
          locale.languageCode == 'mr' ? stotra['stotra_mr'] : stotra['stotra_en'];
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: _fontSize, height: 1.6),
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
        future: _stotraFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final stotraData = snapshot.data!;
            final videoId = stotraData['youtube_video_id'];
            final title = locale.languageCode == 'mr' ? stotraData['title_mr'] : stotraData['title_en'];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildStotraImage(context, stotraData),
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
                            'Check out this stotra: https://www.youtube.com/watch?v=$videoId');
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

  Widget _buildStotraImage(BuildContext context, Map<String, dynamic> stotraData) {
    final theme = Theme.of(context);
    final imageName = stotraData['image'];
    final stotra = widget.stotraList[widget.currentIndex];
    final directory = stotra['directory'] ?? '';

    final imagePath = imageName != null && imageName.isNotEmpty
        ? (directory.isNotEmpty
        ? 'resources/images/stotras/$directory/$imageName'
        : 'resources/images/stotras/$imageName')
        : 'resources/images/stotras/default.jpg';


    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        imagePath,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'resources/images/stotras/default.jpg', // Consistent default
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
