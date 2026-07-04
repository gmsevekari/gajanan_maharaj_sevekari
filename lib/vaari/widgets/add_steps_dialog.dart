import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_service.dart';
import 'package:provider/provider.dart';

/// A single, immediate step/distance submission — Vaari has no live
/// "counting" ritual to stage locally, so this submits directly on tap
/// rather than accumulating in a provider first (unlike the Namjap mala
/// counting flow).
class AddStepsDialog extends StatefulWidget {
  final String eventId;
  final String deviceId;
  final String memberName;
  final String distanceUnit;

  const AddStepsDialog({
    super.key,
    required this.eventId,
    required this.deviceId,
    required this.memberName,
    required this.distanceUnit,
  });

  @override
  State<AddStepsDialog> createState() => _AddStepsDialogState();
}

class _AddStepsDialogState extends State<AddStepsDialog> {
  final _stepsController = TextEditingController();
  final _distanceController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _stepsController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final localizations = AppLocalizations.of(context)!;
    final steps = int.tryParse(_stepsController.text) ?? 0;
    if (steps <= 0) {
      setState(() => _errorText = localizations.fieldRequired);
      return;
    }

    final distanceText = _distanceController.text.trim();
    final parsedDistance = distanceText.isEmpty
        ? null
        : double.tryParse(distanceText);
    // A zero/negative override would make VaariService.submitSteps() reject
    // the whole submission (steps included); treat it as "no override".
    final distanceOverride = (parsedDistance != null && parsedDistance > 0)
        ? parsedDistance
        : null;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final service = context.read<VaariService>();
      await service.submitSteps(
        eventId: widget.eventId,
        deviceId: widget.deviceId,
        memberName: widget.memberName,
        stepsToSubmit: steps,
        distanceToSubmit: distanceOverride,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(localizations.addStepsLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _stepsController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: localizations.stepsLabel,
              hintText: '0',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.directions_walk),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => _errorText = null),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _distanceController,
            decoration: InputDecoration(
              labelText: localizations.distanceOptionalLabel(
                widget.distanceUnit,
              ),
              hintText: '0.0',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.straighten),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(_errorText!, style: TextStyle(color: theme.appColors.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(localizations.submitLabel),
        ),
      ],
    );
  }
}
