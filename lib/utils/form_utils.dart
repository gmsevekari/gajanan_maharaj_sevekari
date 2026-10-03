import 'package:flutter/material.dart';

/// Scrolls the first [FormField] under [formContext] that failed validation
/// into view.
///
/// A long or dialog-hosted form scrolls, so an invalid field is often
/// off-screen, which makes a failed Save look like it did nothing. Call this
/// right after `FormState.validate()` returns false. The scroll is deferred
/// to after the frame so the error text validation just added is already
/// laid out and counted in the scrollable's extent.
void revealFirstInvalidField(BuildContext? formContext) {
  if (formContext == null) return;
  Element? firstInvalid;
  void visit(Element element) {
    if (firstInvalid != null) return;
    if (element.widget is FormField &&
        element is StatefulElement &&
        (element.state as FormFieldState).hasError) {
      firstInvalid = element;
      return;
    }
    element.visitChildren(visit);
  }

  formContext.visitChildElements(visit);
  final target = firstInvalid;
  if (target == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!target.mounted) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 200),
      alignment: 0.1,
    );
  });
}
