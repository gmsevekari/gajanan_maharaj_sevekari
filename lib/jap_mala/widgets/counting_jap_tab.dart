import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

class CountingJapTab extends StatefulWidget {
  const CountingJapTab({super.key});

  @override
  State<CountingJapTab> createState() => _CountingJapTabState();
}

class _CountingJapTabState extends State<CountingJapTab> {
  List<Map<String, dynamic>>? _chants;
  Map<String, dynamic>? _selectedChant;
  int _targetMalas = 1; // Default target
  int? _customTargetMalas; // Persistent custom target
  int _currentCount = 0;
  int _completedMalas = 0;
  final int _countsPerMala = 108;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int _totalJapsToPlay = 0;
  int _japsPlayed = 0;

  @override
  void initState() {
    super.initState();
    _loadChants();
    _loadCustomTarget();

    // Listen to audio completion to increment counts and replay
    _audioPlayer.onPlayerComplete.listen((event) {
      _incrementCount();
      if (_isPlaying) {
        _playNextJap();
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable(); // Ensure wakelock is released
    _audioPlayer.dispose();
    super.dispose();
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

  Future<void> _loadCustomTarget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customTargetMalas = prefs.getInt('customTargetMalas');
    });
  }

  void _incrementCount() {
    // Guard: ignore spurious completion events after stop (e.g. from _audioPlayer.stop())
    if (!_isPlaying) return;

    bool targetReached = false;

    setState(() {
      _currentCount++;
      _japsPlayed++;
      HapticFeedback.lightImpact();

      if (_currentCount >= _countsPerMala) {
        _completedMalas++;
        _currentCount = 0; // Reset for next mala

        // Let user know a mala is complete via heavier haptic
        HapticFeedback.heavyImpact();
      }

      // Flag stop condition — handle outside setState
      if (_japsPlayed >= _totalJapsToPlay) {
        targetReached = true;
      }
    });

    // Use microtask so _stopAudio's setState runs outside the plugin callback,
    // guaranteeing the stop button disappears even if the event fires from native code.
    if (targetReached) {
      Future.microtask(() {
        if (!mounted) return;
        _stopAudio();
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.targetMalasCompleted(
                _formatNumber(context, _targetMalas, pad: false),
              ),
            ),
          ),
        );
      });
    }
  }

  void _playNextJap() {
    if (_selectedChant != null && _selectedChant!.containsKey('audio')) {
      final audioFile = _selectedChant!['audio'];
      _audioPlayer.audioCache = AudioCache(prefix: '');
      _audioPlayer.play(AssetSource('resources/audio/naamjap/$audioFile'));
    } else {
      _stopAudio(); // Failsafe if audio missing
    }
  }

  void _startAudio() {
    if (_selectedChant == null) return;

    WakelockPlus.enable(); // Keep screen awake
    setState(() {
      _isPlaying = true;
      _totalJapsToPlay = _targetMalas * _countsPerMala;
    });
    _playNextJap();
  }

  void _stopAudio() {
    WakelockPlus.disable(); // Allow screen to sleep
    setState(() {
      _isPlaying = false;
    });
    _audioPlayer.stop();
  }

  void _resetCount() {
    _stopAudio();
    setState(() {
      _currentCount = 0;
      _completedMalas = 0;
      _japsPlayed = 0;
    });
  }

  void _setTarget(int root) {
    if (_isPlaying) return;
    setState(() {
      _targetMalas = root;
      _resetCount();
    });
  }

  Future<void> _setCustomTarget(int root) async {
    if (_isPlaying) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('customTargetMalas', root);

    setState(() {
      _customTargetMalas = root;
    });
    _setTarget(root);
  }

  void _showCustomTargetDialog(BuildContext context) {
    if (_isPlaying) return;
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.cardColor,
          title: Text(
            localizations.setTarget,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: localizations.enterCustomTarget,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () {
                final val = int.tryParse(controller.text);
                if (val != null && val > 0) {
                  _setCustomTarget(val);
                }
                Navigator.pop(dialogContext);
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    // Calculate grid items
    final targets = [1, 3, 5, 11, 21];

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
                        onChanged: _isPlaying
                            ? null
                            : (Map<String, dynamic>? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedChant = newValue;
                                    _resetCount();
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

            // Progress Indicators (Cards)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
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
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            localizations.mala,
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
                              _targetMalas > 0
                                  ? '${_formatNumber(context, _completedMalas, pad: false)} / ${_formatNumber(context, _targetMalas, pad: false)}'
                                  : _formatNumber(
                                      context,
                                      _completedMalas,
                                      pad: false,
                                    ),
                              style: TextStyle(
                                color: theme.appColors.primarySwatch,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
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
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
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
                              '${_formatNumber(context, _currentCount)} / ${_formatNumber(context, _countsPerMala, pad: false)}',
                              style: TextStyle(
                                color: theme.appColors.primarySwatch,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Target Selection Title
            Text(
              localizations.selectMalaCount,
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

            // Grid for Targets
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 2.5,
              children: [
                ...targets.map((target) {
                  final isSelected = _targetMalas == target;
                  return _buildTargetCard(
                    _formatNumber(context, target, pad: false),
                    target == 1 ? localizations.mala : localizations.malas,
                    isSelected,
                    () => _setTarget(target),
                    theme,
                  );
                }),
                _buildDottedTargetCard(
                  !targets.contains(_targetMalas) && _targetMalas > 0
                      ? (_targetMalas == 1
                            ? localizations.mala
                            : localizations.malas)
                      : (_customTargetMalas != null
                            ? (_customTargetMalas == 1
                                  ? localizations.mala
                                  : localizations.malas)
                            : localizations.other),
                  theme,
                  !targets.contains(_targetMalas) && _targetMalas > 0,
                  number: !targets.contains(_targetMalas) && _targetMalas > 0
                      ? _formatNumber(context, _targetMalas, pad: false)
                      : (_customTargetMalas != null
                            ? _formatNumber(
                                context,
                                _customTargetMalas!,
                                pad: false,
                              )
                            : null),
                  onTap: () {
                    if (_customTargetMalas != null) {
                      _setTarget(_customTargetMalas!);
                    } else {
                      _showCustomTargetDialog(context);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Big Start/Stop Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isPlaying || _currentCount > 0)
                  GestureDetector(
                    onTap: _resetCount,
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
                      child: const Icon(
                        Icons.stop,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  ),

                ElevatedButton.icon(
                  onPressed: _isPlaying ? _stopAudio : _startAudio,
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 28,
                  ),
                  label: Text(
                    _isPlaying
                        ? 'Pause'
                        : localizations
                              .startPlay, // Using standard english pause
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
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
                    _isPlaying
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
  }

  Widget _buildTargetCard(
    String number,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    Color cardColor;
    Color textColor;

    if (isSelected) {
      cardColor = theme.appColors.primarySwatch[200]!;
      textColor = theme.appColors.primarySwatch[800]!;
    } else {
      cardColor = theme.cardTheme.color ?? theme.cardColor;
      textColor = theme.appColors.primarySwatch[600]!;
    }

    return Card(
      elevation: theme.cardTheme.elevation ?? 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isSelected
              ? theme.appColors.primarySwatch
              : theme.appColors.primarySwatch,
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                subtitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDottedTargetCard(
    String subtitle,
    ThemeData theme,
    bool isSelected, {
    String? number,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: theme.cardTheme.elevation ?? 1,
      color: isSelected
          ? theme.appColors.primarySwatch[200]!
          : theme.cardTheme.color ?? theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isSelected
              ? theme.appColors.primarySwatch
              : theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap ?? () => _showCustomTargetDialog(context),
        borderRadius: BorderRadius.circular(12.0),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: DashedRectPainter(
                  color: isSelected
                      ? theme.appColors.primarySwatch
                      : theme.colorScheme.outlineVariant,
                  strokeWidth: 2,
                  gap: 5,
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (number != null)
                    Text(
                      number,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    )
                  else
                    const Icon(Icons.add, color: Colors.grey, size: 20),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      subtitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (number != null)
              Positioned(
                top: 4,
                right: 6,
                child: GestureDetector(
                  onTap: () => _showCustomTargetDialog(context),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: isSelected
                        ? theme.appColors.primarySwatch[800]!.withValues(
                            alpha: 0.6,
                          )
                        : Colors.grey.withValues(alpha: 0.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
    );

    // A simple dashed path effect code (Using specialized packages is normally preferred)
    // For now returning simple rectangle to satisfy constraints since there's no native dashed border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
