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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: otherConfig.order.map((key) {
            final content = otherMap[key];
            if (content == null) return const SizedBox.shrink();

            // Region check
            if (content.regions.isNotEmpty &&
                !content.regions.contains(deviceCountryCode)) {
              return const SizedBox.shrink(); // Do not build the card if region doesn't match
            }

            final title = _getTitle(localizations, content.titleKey);

            return _buildOtherCard(context, theme, title, () {
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
          }).toList(),
        ),
      ),
    );
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
    VoidCallback onTap,
  ) {
    return Card(
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: theme.colorScheme.primary,
          size: 16.0,
        ),
        onTap: onTap,
      ),
    );
  }
}
