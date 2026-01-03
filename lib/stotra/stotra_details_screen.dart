import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class StotraDetailsScreen extends StatefulWidget {
  final List<Map<String, String>> stotraList;
  final int currentIndex;

  const StotraDetailsScreen({super.key, required this.stotraList, required this.currentIndex});

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
    final stotra = widget.stotraList[widget.currentIndex];
    final directory = stotra['directory'] ?? '';
    final path = directory.isNotEmpty
        ? 'resources/texts/stotras/$directory/${stotra['fileName']}'
        : 'resources/texts/stotras/${stotra['fileName']}';
    final String response = await rootBundle.loadString(path);
    final data = await json.decode(response);
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
        ),
      ),
    );
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
                    return Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2,);
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
                _buildListenTab(),
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

  Widget _buildListenTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text('Audio player will be implemented here.', textAlign: TextAlign.center,),
        ],
      ),
    );
  }
}
