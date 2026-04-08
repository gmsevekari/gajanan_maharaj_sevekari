import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/providers/jap_mala_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:provider/provider.dart';
class TimeBasedJapTab extends StatefulWidget {
  const TimeBasedJapTab({super.key});

  @override
  State<TimeBasedJapTab> createState() => _TimeBasedJapTabTabState();
}

class _TimeBasedJapTabTabState extends State<TimeBasedJapTab> {
  List<Map<String, dynamic>>? _chants;
  Map<String, dynamic>? _selectedChant;

  bool _isTimeUp = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late JapMalaProvider _provider;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _loadChants();
    _provider = context.read<JapMalaProvider>();

    // Listen to audio completion to increment counts and replay
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_provider.isPlaying) {
        if (_provider.isTimerExpired) {
          _stopTimer();
          HapticFeedback.heavyImpact(); // Vibrate when fully done
          if (mounted) {
            final localizations = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localizations.japTimeCompleted)),
            );
          }
        } else {
          _provider.increment();
          HapticFeedback.lightImpact();
          _playNextJap();
        }
      }
    });

    _provider.addListener(_onProviderStateChanged);
  }

  void _onProviderStateChanged() {
    final provider = context.read<JapMalaProvider>();
    if (!provider.isPlaying && _audioPlayer.state == PlayerState.playing) {
      _audioPlayer.stop();
      WakelockPlus.disable();
    }
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

  void _playNextJap() {
    final provider = context.read<JapMalaProvider>();
    if (!provider.isPlaying || _isTimeUp || provider.remainingSeconds <= 0) {
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
    final provider = context.read<JapMalaProvider>();
    if (provider.selectedHours == 0 && provider.selectedMinutes == 0) return;

    _isTimeUp = false;
    WakelockPlus.enable(); // Keep screen awake
    provider.startTimeBasedSession();
    _playNextJap();
  }

  void _stopTimer() {
    WakelockPlus.disable(); // Allow screen to sleep
    _isTimeUp = false;
    context.read<JapMalaProvider>().stop();
    _audioPlayer.stop();
  }

  void _resetTimer() {
    _stopTimer();
    context.read<JapMalaProvider>().reset();
  }

  String _formatTime(BuildContext context, int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    final locale = Localizations.localeOf(context).languageCode;
    return '${formatNumberLocalized(h, locale)}:${formatNumberLocalized(m, locale)}:${formatNumberLocalized(s, locale)}';
  }

  void _showDurationPicker(BuildContext context) {
    final provider = context.read<JapMalaProvider>();
    if (provider.isPlaying) return; // Prevent changing time while running

    int tempHours = provider.selectedHours;
    int tempMinutes = provider.selectedMinutes;
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
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
                                  formatNumberLocalized(index, locale, pad: false),
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
                                  formatNumberLocalized(index, locale, pad: false),
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
                await provider.setDuration(tempHours, tempMinutes);
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
    _provider.removeListener(_onProviderStateChanged);
    WakelockPlus.disable(); // Ensure wakelock is released
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    return Consumer<JapMalaProvider>(
      builder: (context, provider, child) {
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
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.appColors.primarySwatch,
                      width: 2,
                    ),
                  ),
                  child: _chants == null
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<Map<String, dynamic>>(
                            value: _selectedChant,
                            isExpanded: true,
                            alignment: Alignment.center,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: theme.colorScheme.onSurface,
                            ),
                            isDense: true,
                            dropdownColor: theme.cardTheme.color ?? theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            onChanged: provider.isPlaying
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
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
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

                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 32,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.cardColor,
                      border: Border.all(
                        color: theme.appColors.primarySwatch,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          localizations.jap,
                          style: TextStyle(
                            color: theme.appColors.primarySwatch,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatNumberLocalized(provider.currentCount, locale, pad: false),
                            style: TextStyle(
                              color: theme.appColors.primarySwatch,
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
                    color: theme.appColors.primarySwatch[600],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.appColors.primarySwatch,
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
                        color: theme.appColors.primarySwatch,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (!provider.isPlaying && provider.remainingSeconds == 0) ...[
                          Text(
                            '${formatNumberLocalized(provider.selectedHours, locale, pad: false)} ${localizations.hours} ${formatNumberLocalized(provider.selectedMinutes, locale, pad: false)} ${localizations.minutes}',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: theme.appColors.primarySwatch[300],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                localizations.tapToEdit,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.appColors.primarySwatch[300],
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            localizations.timeRemaining,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.appColors.primarySwatch[300],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatTime(context, provider.remainingSeconds),
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.appColors.primarySwatch,
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
                    if (provider.isPlaying ||
                        (provider.remainingSeconds > 0 &&
                            provider.remainingSeconds <
                                ((provider.selectedHours * 3600) +
                                    (provider.selectedMinutes * 60))))
                      GestureDetector(
                        onTap: _resetTimer,
                        child: Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.cardTheme.color ?? theme.cardColor,
                            border: Border.all(
                              color: theme.appColors.primarySwatch,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.stop,
                            color: theme.appColors.error,
                            size: 30,
                          ),
                        ),
                      ),

                    ElevatedButton.icon(
                      onPressed: provider.isPlaying ? _stopTimer : _startTimer,
                      icon: Icon(
                        provider.isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 28,
                      ),
                      label: Text(
                        provider.isPlaying ? 'Pause' : localizations.startPlay,
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
                    Icon(
                      Icons.graphic_eq,
                      color: theme.appColors.primarySwatch,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.isPlaying
                            ? localizations.keepPhoneUnlocked
                            : localizations.audioJapWillStart,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.appColors.primarySwatch.shade300,
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
      },
    );
  }
}
