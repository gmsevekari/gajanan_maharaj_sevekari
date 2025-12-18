import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/routes.dart';
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
    final localizations = AppLocalizations.of(context);
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    final formattedDate = DateFormat.yMMMMd(locale).format(_selectedDate);
    setState(() {
      _sankalpText = localizations.getSankalpGenerated(_locationController.text, formattedDate);
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
    final localizations = AppLocalizations.of(context);
    final locale = Provider.of<LocaleProvider>(context).locale.languageCode;

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.orange[50],
      foregroundColor: Colors.orange[600], // Set text color for the button
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.orange.withAlpha(128), width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.sankalpTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
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
              style: buttonStyle.copyWith(
                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16.0)),
              ),
              onPressed: _generateSankalp,
              child: Text(localizations.generateSankalp),
            ),
            const SizedBox(height: 24.0),
            if (_sankalpText.isNotEmpty)
              Card(
                elevation: 4.0,
                color: Colors.orange[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(color: Colors.orange.withAlpha(128), width: 1),
                ),
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
