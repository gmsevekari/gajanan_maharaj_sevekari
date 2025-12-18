import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/routes.dart';

class StotraDetailsScreen extends StatefulWidget {
  final String stotraFileName;

  const StotraDetailsScreen({super.key, required this.stotraFileName});

  @override
  State<StotraDetailsScreen> createState() => _StotraDetailsScreenState();
}

class _StotraDetailsScreenState extends State<StotraDetailsScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _stotraFuture;
  double _fontSize = 18.0;
  TabController? _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _stotraFuture = _loadStotra();
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
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadStotra() async {
    final String response = await rootBundle.loadString('resources/texts/stotras/${widget.stotraFileName}');
    final data = await json.decode(response);
    return data;
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(10.0, 40.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: _stotraFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final stotra = snapshot.data!;
              final title = locale.languageCode == 'mr' ? stotra['title_mr'] : stotra['title_en'];
              return Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold));
            } else {
              return const Text(''); // Placeholder while loading
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Material(
            color: Colors.orange,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
              tabs: [
                Tab(text: localizations.read),
                Tab(text: localizations.listen),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Read Tab
          FutureBuilder<Map<String, dynamic>>(
            future: _stotraFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                final stotra = snapshot.data!;
                final text = locale.languageCode == 'mr' ? stotra['stotra_mr'] : stotra['stotra_en'];
                return Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // Added bottom padding
                    child: Center(
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: _fontSize),
                      ),
                    ),
                  ),
                  floatingActionButton: _currentIndex == 0 ? Column(
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
                  ) : null,
                );
              } else {
                return const Center(child: Text('No data'));
              }
            },
          ),
          // Listen Tab
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note, size: 100, color: Colors.grey),
                SizedBox(height: 20),
                Text('Audio player will be implemented here.', textAlign: TextAlign.center,),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
