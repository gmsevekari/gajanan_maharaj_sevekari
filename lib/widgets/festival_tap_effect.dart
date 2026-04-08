import 'package:flutter/material.dart';

class FestivalTapEffect extends StatelessWidget {
  final Widget child;

  const FestivalTapEffect({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Falling petals on tap have been removed for Ganesh Chaturthi per user request.
    return child;
  }
}
