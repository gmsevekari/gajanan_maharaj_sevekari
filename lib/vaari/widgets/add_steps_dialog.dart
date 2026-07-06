import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:provider/provider.dart';

/// Allows users to choose between entering steps or distance, and shows the
/// calculated estimate of the other field in real-time.
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
  final _inputController = TextEditingController();
  String _inputType = 'steps'; // 'steps' or 'distance'
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChange);
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputChange);
    _inputController.dispose();
    super.dispose();
  }

  void _onInputChange() {
    if (_errorText != null) {
      setState(() => _errorText = null);
    }
  }

  double get _factor => widget.distanceUnit == 'mi' ? 0.0005 : 0.0008;

  void _toggleInputType(String newType) {
    if (newType == _inputType) return;
    setState(() {
      final text = _inputController.text.trim();
      if (newType == 'distance') {
        final steps = int.tryParse(text) ?? 0;
        final distance = steps * _factor;
        _inputController.text = distance > 0 ? distance.toStringAsFixed(2) : '';
      } else {
        final distance = double.tryParse(text) ?? 0.0;
        final steps = (distance / _factor).round();
        _inputController.text = steps > 0 ? steps.toString() : '';
      }
      _inputType = newType;
      _errorText = null;
    });
  }

  Future<void> _handleSubmit() async {
    final localizations = AppLocalizations.of(context)!;
    final text = _inputController.text.trim();

    int stepsToSubmit = 0;
    double? distanceToSubmit;

    if (_inputType == 'steps') {
      final steps = int.tryParse(text) ?? 0;
      if (steps <= 0) {
        setState(() => _errorText = localizations.fieldRequired);
        return;
      }
      stepsToSubmit = steps;
      distanceToSubmit = null; // Service will calculate using factor
    } else {
      final distance = double.tryParse(text) ?? 0.0;
      if (distance <= 0) {
        setState(() => _errorText = localizations.fieldRequired);
        return;
      }
      stepsToSubmit = (distance / _factor).round();
      distanceToSubmit = distance;
    }

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
        stepsToSubmit: stepsToSubmit,
        distanceToSubmit: distanceToSubmit,
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
    final locale = Localizations.localeOf(context).languageCode;
    final text = _inputController.text.trim();

    String calculationLabel = '';
    if (text.isNotEmpty) {
      if (_inputType == 'steps') {
        final steps = int.tryParse(text) ?? 0;
        final distance = steps * _factor;
        calculationLabel = localizations.estimatedDistance(
          formatDistanceLocalized(distance, locale),
          widget.distanceUnit,
        );
      } else {
        final distance = double.tryParse(text) ?? 0.0;
        final steps = (distance / _factor).round();
        calculationLabel = localizations.estimatedSteps(
          formatNumberLocalized(steps, locale, pad: false),
        );
      }
    }

    return AlertDialog(
      title: Text(localizations.addStepsOrDistanceTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              segments: [
                ButtonSegment(
                  value: 'steps',
                  label: Text(localizations.stepsLabel),
                  icon: const Icon(Icons.directions_walk, size: 16),
                ),
                ButtonSegment(
                  value: 'distance',
                  label: Text(localizations.distanceLabel),
                  icon: const Icon(Icons.straighten, size: 16),
                ),
              ],
              selected: {_inputType},
              onSelectionChanged: (value) => _toggleInputType(value.first),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _inputController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: _inputType == 'steps'
                    ? localizations.stepsLabel
                    : localizations.distanceOptionalLabel(widget.distanceUnit),
                hintText: _inputType == 'steps' ? '0' : '0.0',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  _inputType == 'steps' ? Icons.directions_walk : Icons.straighten,
                ),
              ),
              keyboardType: _inputType == 'steps'
                  ? TextInputType.number
                  : const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: _inputType == 'steps'
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            ),
            if (calculationLabel.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                calculationLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.appColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(_errorText!, style: TextStyle(color: theme.appColors.error)),
            ],
          ],
        ),
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
