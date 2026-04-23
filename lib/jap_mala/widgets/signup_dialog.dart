import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';

class SignupDialog extends StatelessWidget {
  final GroupNamjapEvent event;

  const SignupDialog({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Signup (Placeholder)'),
      content: const Text('Signup flow will be implemented in Task 5.1'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
