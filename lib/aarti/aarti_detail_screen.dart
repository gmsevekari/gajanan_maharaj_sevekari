import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class AartiDetailScreen extends StatefulWidget {
  final String aartiFileName;
  final String aartiDirectory;

  const AartiDetailScreen({super.key, required this.aartiFileName, required this.aartiDirectory});

  @override
  State<AartiDetailScreen> createState() => _AartiDetailScreenState();
}

class _AartiDetailScreenState extends State<AartiDetailScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _aartiFuture;
  double _fontSize = 18.0;
  TabController? _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _aartiFuture = _loadAarti();
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

  Future<Map<String, dynamic>> _loadAarti() async {
    final String response = await rootBundle.loadString('resources/texts/aartis/${widget.aartiDirectory}/${widget.aartiFileName}');
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
          future: _aartiFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final aarti = snapshot.data!;
              final title = locale.languageCode == 'mr' ? aarti['title_mr'] : aarti['title_en'];
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
                // Read Tab
                FutureBuilder<Map<String, dynamic>>(
                  future: _aartiFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData) {
                      final aarti = snapshot.data!;
                      final text = locale.languageCode == 'mr' ? aarti['aarti_mr'] : aarti['aarti_en'];
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
          ),
        ],
      ),
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
                  Icons.menu_book,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
              if (index == 0)
                const SizedBox(width: 8),
              if (index == 1) // Listen tab
                Icon(
                  Icons.play_arrow,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
              if (index == 1)
                const SizedBox(width: 8),
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
}
