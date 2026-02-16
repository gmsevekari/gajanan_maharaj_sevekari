import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SankalpScreen extends StatefulWidget {
  const SankalpScreen({super.key});

  @override
  _SankalpScreenState createState() => _SankalpScreenState();
}

class _SankalpScreenState extends State<SankalpScreen> {
  final TextEditingController _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _sankalpText = '';

  void _generateSankalp() {
    final localizations = AppLocalizations.of(context)!;
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    final formattedDate = DateFormat.yMMMMd(locale).format(_selectedDate);
    setState(() {
      _sankalpText = localizations.sankalpGenerated(formattedDate, _locationController.text);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: locale,
      initialDate: _selectedDate,
      firstDate: DateTime(2020), 
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final localizations = AppLocalizations.of(context)!;
    final locale = Provider.of<LocaleProvider>(context).locale.languageCode;
    final buttonStyle = theme.elevatedButtonTheme.style;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.sankalpTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: localizations.location,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${localizations.date}: ${DateFormat.yMMMMd(locale).format(_selectedDate)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => _selectDate(context),
                  child: Text(localizations.selectDate),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              style: buttonStyle?.copyWith(
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16.0)),
              ),
              onPressed: _generateSankalp,
              child: Text(localizations.generateSankalp),
            ),
            const SizedBox(height: 24.0),
            if (_sankalpText.isNotEmpty)
              Card(
                elevation: theme.cardTheme.elevation,
                color: theme.cardTheme.color,
                shape: theme.cardTheme.shape,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _sankalpText,
                    style: const TextStyle(fontSize: 18.0),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }
}
