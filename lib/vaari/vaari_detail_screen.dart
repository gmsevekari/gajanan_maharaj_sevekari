import 'package:flutter/material.dart';

class VaariDetailScreen extends StatelessWidget {
  final String eventId;
  final String? prefilledJoinCode;

  const VaariDetailScreen({
    super.key,
    required this.eventId,
    this.prefilledJoinCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaari Detail'),
      ),
      body: Center(
        child: Text('Vaari Detail Screen for Event: $eventId'),
      ),
    );
  }
}
