import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class TimeBasedJapTab extends StatefulWidget {
  const TimeBasedJapTab({super.key});

  @override
  State<TimeBasedJapTab> createState() => _TimeBasedJapTabTabState();
}

class _TimeBasedJapTabTabState extends State<TimeBasedJapTab> {
  List<Map<String, dynamic>>? _chants;
  Map<String, dynamic>? _selectedChant;
  int _selectedHours = 0;
  int _selectedMinutes = 10;

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _loadChants();
  }

  Future<void> _loadChants() async {
    final String response = await rootBundle.loadString(
      'resources/texts/naamjap/naamjap.json',
    );
    final data = await json.decode(response);
    final List chantsJson = data['chants'] ?? [];
    final chants = chantsJson.cast<Map<String, dynamic>>();
    if (mounted) {
      setState(() {
        _chants = chants;
        if (chants.isNotEmpty) {
          _selectedChant = chants.first;
        }
      });
    }
  }

  void _startTimer() {
    if (_selectedHours == 0 && _selectedMinutes == 0) return;

    setState(() {
      if (_remainingSeconds == 0) {
        _remainingSeconds = (_selectedHours * 3600) + (_selectedMinutes * 60);
      }
      _isRunning = true;
    });

    WakelockPlus.enable(); // Keep screen awake

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _stopTimer();
        HapticFeedback.heavyImpact(); // Vibrate when done
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Jap time completed!')));
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    WakelockPlus.disable(); // Allow screen to sleep
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _remainingSeconds = 0;
    });
  }

  String _formatTime(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showDurationPicker(BuildContext context) {
    if (_isRunning) return; // Prevent changing time while running

    int tempHours = _selectedHours;
    int tempMinutes = _selectedMinutes;
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.duration),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(localizations.hours),
                          DropdownButton<int>(
                            value: tempHours,
                            items: List.generate(
                              24,
                              (index) => DropdownMenuItem(
                                value: index,
                                child: Text('$index'),
                              ),
                            ),
                            onChanged: (val) {
                              if (val != null)
                                setDialogState(() => tempHours = val);
                            },
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(localizations.minutes),
                          DropdownButton<int>(
                            value: tempMinutes,
                            items: List.generate(
                              60,
                              (index) => DropdownMenuItem(
                                value: index,
                                child: Text('$index'),
                              ),
                            ),
                            onChanged: (val) {
                              if (val != null)
                                setDialogState(() => tempMinutes = val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedHours = tempHours;
                  _selectedMinutes = tempMinutes;
                  _remainingSeconds =
                      (_selectedHours * 3600) + (_selectedMinutes * 60);
                });
                Navigator.pop(context);
              },
              child: Text(localizations.ok),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable(); // Ensure wakelock is released
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Image Banner
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'resources/images/naamjap/naamjap.png',
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: _chants == null
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: _selectedChant,
                        alignment: Alignment.center,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: theme.colorScheme.onSurface,
                        ),
                        isDense: true,
                        dropdownColor: theme.cardTheme.color ?? theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        onChanged: (Map<String, dynamic>? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedChant = newValue;
                            });
                          }
                        },
                        items: _chants!.map((Map<String, dynamic> chant) {
                          final title = locale == 'mr'
                              ? chant['title_mr']
                              : chant['title_en'];
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: chant,
                            alignment: Alignment.center,
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Time Selection Area
            Text(
              localizations.duration,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Current Time / Editable Card
            GestureDetector(
              onTap: () => _showDurationPicker(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isRunning
                        ? Colors.orange
                        : theme.colorScheme.outlineVariant,
                    width: _isRunning ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    if (!_isRunning && _remainingSeconds == 0) ...[
                      Text(
                        '$_selectedHours ${localizations.hours} $_selectedMinutes ${localizations.minutes}',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            localizations.tapToEdit,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        localizations.timeRemaining,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Big Start/Pause Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_remainingSeconds > 0)
                  GestureDetector(
                    onTap: _resetTimer,
                    child: Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.cardTheme.color ?? theme.cardColor,
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      child: const Icon(
                        Icons.stop,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  ),

                ElevatedButton.icon(
                  onPressed: _isRunning ? _stopTimer : _startTimer,
                  icon: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    size: 28,
                  ),
                  label: Text(
                    _isRunning ? 'Pause' : localizations.startPlay,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.graphic_eq, color: Colors.orange[300], size: 16),
                const SizedBox(width: 8),
                Text(
                  localizations.audioJapWillStart,
                  style: TextStyle(color: Colors.orange[300]),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
