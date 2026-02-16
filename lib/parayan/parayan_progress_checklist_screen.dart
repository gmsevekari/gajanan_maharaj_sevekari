import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParayanProgressChecklistScreen extends StatefulWidget {
  final ParayanType parayanType;

  const ParayanProgressChecklistScreen({super.key, required this.parayanType});

  @override
  _ParayanProgressChecklistScreenState createState() =>
      _ParayanProgressChecklistScreenState();
}

class _ParayanProgressChecklistScreenState
    extends State<ParayanProgressChecklistScreen> {
  late Future<List<bool>> _loadProgressFuture;
  late List<bool> _completedAdhyays;

  @override
  void initState() {
    super.initState();
    _loadProgressFuture = _loadProgress();
  }

  Future<List<bool>> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = List.generate(21, (i) => prefs.getBool('adhyay_${i + 1}') ?? false);
    _completedAdhyays = completed;
    return completed;
  }

  Future<void> _saveProgress(int adhyayIndex, bool isCompleted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhyay_${adhyayIndex + 1}', isCompleted);
    setState(() {
      _completedAdhyays[adhyayIndex] = isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parayanType == ParayanType.oneDay
            ? localizations.oneDayParayanProgress
            : localizations.threeDayParayanProgress, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<bool>>(
        future: _loadProgressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading progress'));
          } else if (snapshot.hasData) {
            return _buildChecklist(context, localizations);
          } else {
            return const Center(child: Text('No progress found'));
          }
        },
      ),
    );
  }

  Widget _buildChecklist(BuildContext context, AppLocalizations localizations) {
    if (widget.parayanType == ParayanType.oneDay) {
      return ListView.builder(
          itemCount: 21,
          itemBuilder: (context, index) => _buildChecklistItem(index, localizations));
    } else {
      return ListView(
        children: [
          _buildDayCard(context, 1, 1, 9, localizations),
          _buildDayCard(context, 2, 10, 15, localizations),
          _buildDayCard(context, 3, 16, 21, localizations),
        ],
      );
    }
  }

  Widget _buildDayCard(BuildContext context, int day, int startAdhyay,
      int endAdhyay, AppLocalizations localizations) {
    final theme = Theme.of(context);

    return Card(
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('${localizations.day} $day', style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold, fontSize: 20.0)),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: endAdhyay - startAdhyay + 1,
              itemBuilder: (context, index) {
                final adhyayIndex = startAdhyay + index - 1;
                return _buildChecklistItem(adhyayIndex, localizations);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(int adhyayIndex, AppLocalizations localizations) {
    final adhyayNumber = adhyayIndex + 1;
    return Card(
      elevation: 2.0,
      color: _completedAdhyays[adhyayIndex] ? Colors.green[100] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: _completedAdhyays[adhyayIndex] ? Colors.green : Colors.grey.withAlpha(128), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: CheckboxListTile(
        title: Text('${localizations.adhyay} $adhyayNumber', style: TextStyle(fontWeight: FontWeight.bold, color: _completedAdhyays[adhyayIndex] ? Colors.green[800] : Colors.black)),
        value: _completedAdhyays[adhyayIndex],
        onChanged: (bool? value) {
          if (value != null) {
            _saveProgress(adhyayIndex, value);
          }
        },
        activeColor: Colors.green,
      ),
    );
  }
}
