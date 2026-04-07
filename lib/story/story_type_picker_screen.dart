import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/story/story_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';

class StoryTypePickerScreen extends StatelessWidget {
  final DeityConfig deity;

  const StoryTypePickerScreen({super.key, required this.deity});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Helper to check if this deity has content for a given story type
    bool hasTypeContent(String type) {
      final configForType = deity.nityopasana.kidsStories?[type];
      return configForType?.hasContent ?? false;
    }

    final showRead = hasTypeContent('stories');
    final showListen = hasTypeContent('audios');
    final showWatch = hasTypeContent('videos');

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.homeStoriesTitle),
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            if (showRead)
              _buildTypeCard(
                context,
                title: localizations.storiesTitle,
                icon: Icons.menu_book_rounded,
                type: 'stories',
              ),
            if (showRead && (showListen || showWatch))
              const SizedBox(height: 12),
            if (showListen)
              _buildTypeCard(
                context,
                title: localizations.audiosTitle,
                icon: Icons.headset_rounded,
                type: 'audios',
              ),
            if (showListen && showWatch) const SizedBox(height: 12),
            if (showWatch)
              _buildTypeCard(
                context,
                title: localizations.videosTitle,
                icon: Icons.play_circle_fill_rounded,
                type: 'videos',
              ),
            if (!showRead && !showListen && !showWatch)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Text(
                    'No stories available at the moment.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String type,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.appColors.primarySwatch;

    return Card(
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final config = deity.nityopasana.kidsStories![type]!;
          final mode = config.isCategorized
              ? StoryListMode.category
              : (config.isGrouped ? StoryListMode.group : StoryListMode.file);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryListScreen(
                storyType: type,
                mode: mode,
                deity: deity,
              ),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ghost Icon on the right
            Positioned(
              right: -10,
              bottom: -15,
              child: Icon(
                icon,
                size: 80,
                color: primaryColor.withValues(alpha: 0.08),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 24),
              ),
              title: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                color: primaryColor.withValues(alpha: 0.5),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
