import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/shared/global_search_delegate.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';

class OtherScreen extends StatelessWidget {
  const OtherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final appConfig = Provider.of<AppConfigProvider>(context).appConfig!;
    final otherConfig = appConfig.other;
    final defaultDeity = appConfig.deities.first;
    final String? deviceCountryCode = View.of(
      context,
    ).platformDispatcher.locale.countryCode;

    final otherMap = {
      'sunday_prarthana': otherConfig.sundayPrarthana,
      'other_aartis': otherConfig.otherAartis,
      'other_stotras': otherConfig.otherStotras,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.otherTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(
                  hintText: localizations.searchHint,
                ),
              );
            },
          ),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  ...otherConfig.order.map((key) {
                    final content = otherMap[key];
                    if (content == null) return const SizedBox.shrink();

                    if (content.regions.isNotEmpty &&
                        !content.regions.contains(deviceCountryCode)) {
                      return const SizedBox.shrink(); 
                    }

                    final title = _getTitle(localizations, content.titleKey);
                    final icon = _getIcon(key);

                    return _buildOtherCard(context, theme, title, icon, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContentListScreen(
                            deity: defaultDeity,
                            title: title,
                            contentType: ContentTypeExtension.fromString(
                              content.contentType,
                            ),
                            content: content,
                          ),
                        ),
                      );
                    });
                  }),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String key) {
    switch (key) {
      case 'sunday_prarthana':
        return Icons.auto_stories;
      case 'other_aartis':
        return Icons.lyrics_outlined;
      case 'other_stotras':
        return Icons.menu_book_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getTitle(AppLocalizations localizations, String key) {
    switch (key) {
      case 'sundayPrarthanaTitle':
        return localizations.sundayPrarthanaTitle;
      case 'otherAartis':
        return localizations.otherAartis;
      case 'otherStotras':
        return localizations.otherStotras;
      default:
        return '';
    }
  }

  Widget _buildOtherCard(
    BuildContext context,
    ThemeData theme,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 24) / 2,
      child: AspectRatio(
        aspectRatio: 1.4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: theme.cardTheme.shadowColor!,
                offset: const Offset(0, 4),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: theme.cardTheme.color,
            shape: theme.cardTheme.shape,
            child: InkWell(
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40.0, color: theme.iconTheme.color),
                  const SizedBox(height: 8.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
