import 'package:flutter/material.dart';

class BhajanDetailScreen extends StatefulWidget {
  final String bhajanTitle;

  const BhajanDetailScreen({super.key, required this.bhajanTitle});

  @override
  _BhajanDetailScreenState createState() => _BhajanDetailScreenState();
}

class _BhajanDetailScreenState extends State<BhajanDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _fontSize = 18.0;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bhajanTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: () => setState(() => _fontSize = _fontSize > 12 ? _fontSize - 2 : 12)),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: () => setState(() => _fontSize = _fontSize < 40 ? _fontSize + 2 : 40)),
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Read'),
            Tab(text: 'Listen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReadTab(),
          _buildListenTab(),
        ],
      ),
    );
  }

  Widget _buildReadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'This is the text for the Bhajan. The full Marathi text will be displayed here.',
        style: TextStyle(fontSize: _fontSize),
      ),
    );
  }

  Widget _buildListenTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.play_circle_fill, size: 100, color: Theme.of(context).primaryColor),
        const SizedBox(height: 20),
        Text('Audio player for ${widget.bhajanTitle}'),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: Icon(Icons.skip_previous), onPressed: null),
            IconButton(icon: Icon(Icons.play_arrow), onPressed: null),
            IconButton(icon: Icon(Icons.skip_next), onPressed: null),
          ],
        ),
        const Slider(value: 0.0, onChanged: null),
      ],
    );
  }
}
