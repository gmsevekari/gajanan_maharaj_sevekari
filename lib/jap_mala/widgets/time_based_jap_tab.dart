import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  int _currentCount = 0;
  bool _isTimeUp = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _loadChants();
    _loadCustomTarget();

    // Listen to audio completion to increment counts and replay
    _audioPlayer.onPlayerComplete.listen((event) {
      _incrementCount();
      if (_isRunning) {
        if (_remainingSeconds <= 0 || _isTimeUp) {
          _isTimeUp = false;
          _stopTimer();
          HapticFeedback.heavyImpact(); // Vibrate when fully done
          if (mounted) {
            final localizations = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localizations.japTimeCompleted)),
            );
          }
        } else {
          _playNextJap();
        }
      }
    });
  }

  Future<void> _loadCustomTarget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedHours = prefs.getInt('timeBasedJapHours') ?? 0;
      _selectedMinutes = prefs.getInt('timeBasedJapMinutes') ?? 10;
    });
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

  void _incrementCount() {
    if (!_isRunning) return;

    setState(() {
      _currentCount++;
      HapticFeedback.lightImpact();
    });
  }

  void _playNextJap() {
    if (!_isRunning || _isTimeUp || _remainingSeconds <= 0) {
      return; // Prevent zombie audio if called exactly as timer stops
    }

    if (_selectedChant != null && _selectedChant!.containsKey('audio')) {
      final audioFile = _selectedChant!['audio'];
      _audioPlayer.audioCache = AudioCache(prefix: '');
      _audioPlayer.play(AssetSource('resources/audio/naamjap/$audioFile'));
    } else {
      _stopTimer(); // Failsafe if audio missing
    }
  }

  void _startTimer() {
    if (_selectedHours == 0 && _selectedMinutes == 0) return;

    setState(() {
      _isTimeUp = false;
      if (_remainingSeconds == 0) {
        _remainingSeconds = (_selectedHours * 3600) + (_selectedMinutes * 60);
        _currentCount = 0; // Reset chant counter on a completely fresh start
      }
      _isRunning = true;
    });

    WakelockPlus.enable(); // Keep screen awake
    _playNextJap();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _remainingSeconds = 0;
          _isTimeUp = true;
        });
        timer.cancel(); // Let the audio naturally finish the final chant
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    WakelockPlus.disable(); // Allow screen to sleep
    _isTimeUp = false;

    // Stop audio physically synchronously to guarantee immediate halt
    _audioPlayer.stop();

    // Use microtask so setState runs outside the timer loop / plugin callback,
    // guaranteeing the stop button disappears even if called from deep native code.
    Future.microtask(() {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
      });
      _audioPlayer.release();
    });
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _remainingSeconds = 0;
      _currentCount = 0;
    });
  }

  String _formatTime(BuildContext context, int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return '${_formatNumber(context, h, pad: true)}:${_formatNumber(context, m, pad: true)}:${_formatNumber(context, s, pad: true)}';
  }

  String _formatNumber(BuildContext context, int number, {bool pad = true}) {
    String numStr = pad ? number.toString().padLeft(2, '0') : number.toString();
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';
    if (!isMarathi) return numStr;

    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const marathi = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    for (int i = 0; i < english.length; i++) {
      numStr = numStr.replaceAll(english[i], marathi[i]);
    }
    return numStr;
  }

  void _showDurationPicker(BuildContext context) {
    if (_isRunning) return; // Prevent changing time while running

    int tempHours = _selectedHours;
    int tempMinutes = _selectedMinutes;
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.cardColor,
          title: Text(
            localizations.duration,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                          Text(
                            localizations.hours,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<int>(
                            value: tempHours,
                            dropdownColor:
                                theme.cardTheme.color ?? theme.cardColor,
                            items: List.generate(
                              24,
                              (index) => DropdownMenuItem(
                                value: index,
                                child: Text(
                                  _formatNumber(context, index, pad: false),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                // Prevent 0 hours and 0 minutes
                                if (val == 0 && tempMinutes == 0) return;
                                setDialogState(() => tempHours = val);
                              }
                            },
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            localizations.minutes,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<int>(
                            value: tempMinutes,
                            dropdownColor:
                                theme.cardTheme.color ?? theme.cardColor,
                            items: List.generate(
                              60,
                              (index) => DropdownMenuItem(
                                value: index,
                                child: Text(
                                  _formatNumber(context, index, pad: false),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                // Prevent 0 hours and 0 minutes
                                if (tempHours == 0 && val == 0) return;
                                setDialogState(() => tempMinutes = val);
                              }
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
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _selectedHours = tempHours;
                  _selectedMinutes = tempMinutes;
                  _resetTimer();
                });

                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('timeBasedJapHours', tempHours);
                await prefs.setInt('timeBasedJapMinutes', tempMinutes);

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              child: Text(
                localizations.ok,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
    _audioPlayer.dispose();
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
                        onChanged: _isRunning
                            ? null
                            : (Map<String, dynamic>? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedChant = newValue;
                                    _resetTimer();
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

            // Progress Indicators (Cards) - Added from Request #2
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal:
                      32, // slightly wider internal padding makes it match typical dropdown width
                ),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.cardColor,
                  border: Border.all(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize
                      .min, // This fixes the bottom overflow naturally
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      localizations.jap,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatNumber(context, _currentCount, pad: false),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time Selection Area
            Text(
              localizations.duration,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange[600],
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
                  border: Border.all(color: Colors.orange, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (!_isRunning && _remainingSeconds == 0) ...[
                      Text(
                        '${_formatNumber(context, _selectedHours, pad: false)} ${localizations.hours} ${_formatNumber(context, _selectedMinutes, pad: false)} ${localizations.minutes}',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme
                              .colorScheme
                              .primary, // Changed from onSurface
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.orange[300]),
                          const SizedBox(width: 4),
                          Text(
                            localizations.tapToEdit,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.orange[300],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        localizations.timeRemaining,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.orange[300],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(context, _remainingSeconds),
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
                if (_isRunning ||
                    (_remainingSeconds > 0 &&
                        _remainingSeconds <
                            ((_selectedHours * 3600) +
                                (_selectedMinutes * 60))))
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
                const Icon(Icons.graphic_eq, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isRunning
                        ? localizations.keepPhoneUnlocked
                        : localizations.audioJapWillStart,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.orange.shade300,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
