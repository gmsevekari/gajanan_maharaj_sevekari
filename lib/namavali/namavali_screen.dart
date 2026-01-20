import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class NamavaliScreen extends StatefulWidget {
  const NamavaliScreen({super.key});

  @override
  State<NamavaliScreen> createState() => _NamavaliScreenState();
}

class _NamavaliScreenState extends State<NamavaliScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _namavaliFuture;
  double _fontSize = 18.0;
  TabController? _tabController;
  int _currentIndex = 0;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _namavaliFuture = _loadNamavali();
    _tabController = TabController(length: 2, vsync: this);
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

  Future<Map<String, dynamic>> _loadNamavali() async {
    final String response = await rootBundle.loadString('resources/texts/namavali/namavali_108.json');
    final data = await json.decode(response);
    if (data['youtube_video_id'] != null && data['youtube_video_id'].isNotEmpty) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: data['youtube_video_id'],
        flags: const YoutubePlayerFlags(
          autoPlay: false,
        ),
      );
    }
    return data;
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(12.0, 30.0);
    });
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

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.namavaliTitle),
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
              physics: const NeverScrollableScrollPhysics(), // Disable swipe gesture
              children: [
                _buildReadTab(context),
                _buildListenTab(context),
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
                  Icons.format_list_numbered,
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

  Widget _buildReadTab(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    final fontProvider = Provider.of<FontProvider>(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _namavaliFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          final names = data['names'] as List<dynamic>? ?? [];
          final textStyle = isMarathi(locale)
              ? fontProvider.marathiTextStyle.copyWith(fontSize: _fontSize, height: 1.6)
              : fontProvider.englishTextStyle.copyWith(fontSize: _fontSize, height: 1.6);

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 120), // Padding for FloatingActionButtons
            itemCount: names.length + 1, // Add 1 for the footer
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == names.length) {
                // This is the footer
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Image.asset('resources/images/logo/App_Logo.png', height: 50, width: 50),
                      const SizedBox(height: 8),
                      Text(
                        localizations.namavaliFooter,
                        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: theme.colorScheme.secondary),
                      ),
                    ],
                  ),
                );
              }

              final nameData = names[index];
              final name = isMarathi(locale) ? nameData['name_mr'] : nameData['name_en'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(color: Colors.orange[800]),
                  ),
                ),
                title: Text(
                  name,
                  style: textStyle,
                ),
              );
            },
          );
        } else {
          return const Center(child: Text('No names found'));
        }
      },
    );
  }

  Widget _buildListenTab(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return FutureBuilder<Map<String, dynamic>>(
        future: _namavaliFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final namavaliData = snapshot.data!;
            final videoId = namavaliData['youtube_video_id'];

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
                      'resources/images/namavali/108_Namavali.png',
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'resources/images/grantha/default.jpg',
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
                    localizations.namavaliListenTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.spa, color: Colors.orange[200]),
                      ),
                      const Expanded(child: Divider(thickness: 1)),
                    ],
                  ),
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
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.share, color: theme.colorScheme.primary),
                              onPressed: () {
                                SharePlus.instance.share(
                                    ShareParams(
                                        text: '${localizations
                                            .namavaliShareMessage}: https://www.youtube.com/watch?v=$videoId'
                                    )
                                );
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
                      color: Colors.orange.withValues(alpha: 0.1),
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

  bool isMarathi(Locale locale) => locale.languageCode == 'mr';
}
