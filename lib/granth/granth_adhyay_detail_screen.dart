import 'package:flutter/material.dart';

class GranthAdhyayDetailScreen extends StatefulWidget {
  final int adhyayNumber;

  const GranthAdhyayDetailScreen({super.key, required this.adhyayNumber});

  @override
  _GranthAdhyayDetailScreenState createState() => _GranthAdhyayDetailScreenState();
}

class _GranthAdhyayDetailScreenState extends State<GranthAdhyayDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: Text('Adhyay ${widget.adhyayNumber}'),
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
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Text(
        'This is the text for the Adhyay. The full Marathi text will be displayed here. The text is scrollable and uses large, legible fonts.',
        style: TextStyle(fontSize: 18.0),
      ),
    );
  }

  Widget _buildListenTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.play_circle_fill, size: 100, color: Theme.of(context).primaryColor),
        const SizedBox(height: 20),
        const Text('Audio player for Adhyay'),
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
