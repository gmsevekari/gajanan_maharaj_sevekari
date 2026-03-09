import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/counting_jap_tab.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/time_based_jap_tab.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/manual_jap_tab.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class NaamjapScreen extends StatelessWidget {
  const NaamjapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.orange,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            localizations.naamjapTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25.0),
                    border: Border.all(color: Colors.grey[300]!, width: 1.5),
                  ),
                  child: TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(25.0),
                      color: Colors.orange,
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
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [CountingJapTab(), TimeBasedJapTab(), ManualJapTab()],
        ),
      ),
    );
  }
}
