import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/counting_jap_tab.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/time_based_jap_tab.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/manual_jap_tab.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/jap_mala_provider.dart';

class IndividualNamjapScreen extends StatelessWidget {
  const IndividualNamjapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.appColors.primarySwatch,
          iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
          title: Text(
            localizations.namjapTitle,
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const ThemedIcon(LogicalIcon.home),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.home,
                (route) => false,
              ),
            ),
            IconButton(
              icon: const ThemedIcon(LogicalIcon.settings),
              onPressed: () => Navigator.pushNamed(context, Routes.settings),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64.0),
            child: ColoredBox(
              color: theme.scaffoldBackgroundColor,
              child: Container(
                color: theme.scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.appColors.surface,
                    borderRadius: BorderRadius.circular(25.0),
                    border: Border.all(color: theme.appColors.divider, width: 1.5),
                  ),
                  child: TabBar(
                    labelColor: theme.colorScheme.onPrimary,
                    unselectedLabelColor: theme.appColors.secondaryText,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(25.0),
                      color: theme.appColors.primarySwatch,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.music_note, size: 16),
                            const SizedBox(width: 2),
                            Text(localizations.malas),
                            const SizedBox(width: 4),
                            const Icon(Icons.onetwothree, size: 20),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.music_note, size: 16),
                            const SizedBox(width: 2),
                            Text(localizations.malas),
                            const SizedBox(width: 4),
                            const Icon(Icons.timer, size: 16),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(localizations.malas),
                            const SizedBox(width: 4),
                            const Icon(Icons.onetwothree, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ChangeNotifierProvider(
              create: (_) => JapMalaProvider()..init(),
              child: const CountingJapTab(),
            ),
            ChangeNotifierProvider(
              create: (_) => JapMalaProvider()..init(),
              child: const TimeBasedJapTab(),
            ),
            ChangeNotifierProvider(
              create: (_) => JapMalaProvider()..init(),
              child: const ManualJapTab(),
            ),
          ],
        ),
      ),
    );
  }
}
