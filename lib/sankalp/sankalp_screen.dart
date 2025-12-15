import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/constants.dart';
import 'package:intl/intl.dart';

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
    setState(() {
      final formattedDate = DateFormat.yMMMMd().format(_selectedDate);
      _sankalpText = 'Sankalp for ${_locationController.text} on $formattedDate will be generated here based on the Sampurna Chaturmas book.';
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.sankalpTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: ${DateFormat.yMMMMd().format(_selectedDate)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Select Date'),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _generateSankalp,
              child: const Text('Generate Sankalp'),
            ),
            const SizedBox(height: 24.0),
            if (_sankalpText.isNotEmpty)
              Card(
                elevation: 4.0,
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
