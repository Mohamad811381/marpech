// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/chapter.dart';
import '../models/difficulty.dart';
import '../models/game_palette.dart';
import '../models/level.dart';
import '../services/audio_service.dart';
import '../services/levels_service.dart';
import '../services/localization_service.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  final GamePalette palette;
  final Difficulty difficulty;
  final Chapter chapter;

  const LevelSelectScreen({
    super.key,
    required this.palette,
    required this.difficulty,
    required this.chapter,
  });

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  final AudioService _audio = AudioService();
  int _highestUnlocked = 1;
  Set<int> _completed = {};
  bool _loaded = false;

  GamePalette get p => widget.palette;
  List<Level> get _levels =>
      LevelsService.levelsOfChapter(widget.chapter);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await LevelsService.getHighestUnlocked();
    final c = await LevelsService.getCompleted();
    if (!mounted) return;
    setState(() {
      _highestUnlocked = h;
      _completed = c;
      _loaded = true;
    });
  }

  Future<void> _startLevel(Level level) async {
    await _audio.playSfx(Sfx.button);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          difficulty: widget.difficulty,
          palette: p,
          level: level,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completed
        .where((id) =>
            id >= widget.chapter.startLevelId &&
            id <= widget.chapter.endLevelId)
        .length;
    final accent = widget.chapter.accentColor;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(completedCount, accent),
            if (!_loaded)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: accent),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _levels.length,
                  itemBuilder: (context, i) => _levelCard(_levels[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(int completed, Color accent) {
    final total = _levels.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.chapter.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.chapter.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  L10n.tf('chapters_chapter_progress',
                      {'n': completed, 'm': total}),
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: accent, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$completed/$total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
    return Material(
      color: p.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.border),
          ),
          child: Icon(Icons.arrow_back_rounded,
              color: p.accent, size: 22),
        ),
      ),
    );
  }

  Widget _levelCard(Level level) {
    final unlocked = level.id <= _highestUnlocked;
    final completed = _completed.contains(level.id);
    final accent = widget.chapter.accentColor;
    // شماره‌ی محلی (۱ تا ۱۰ برای هر فصل)
    final localNum = level.id - widget.chapter.startLevelId + 1;

    return GestureDetector(
      onTap: unlocked ? () => _startLevel(level) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: completed
              ? LinearGradient(
                  colors: [
                    accent.withOpacity(0.22),
                    p.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: completed ? null : p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: completed
                ? accent.withOpacity(0.6)
                : unlocked
                    ? p.border
                    : p.border.withOpacity(0.35),
            width: completed ? 2 : 1,
          ),
          boxShadow: completed
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.2),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Text(
                  '#$localNum',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: unlocked
                        ? p.textMuted
                        : p.textMuted.withOpacity(0.4),
                  ),
                ),
              ),
              if (completed)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Icon(
                    Icons.verified_rounded,
                    color: accent,
                    size: 20,
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!unlocked)
                      Icon(
                        Icons.lock_rounded,
                        color: p.textMuted.withOpacity(0.5),
                        size: 40,
                      )
                    else
                      Text(
                        level.emoji,
                        style: const TextStyle(fontSize: 42),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      level.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: unlocked
                            ? p.textPrimary
                            : p.textMuted.withOpacity(0.5),
                      ),
                    ),
                    if (unlocked) ...[
                      const SizedBox(height: 4),
                      Text(
                        L10n.tf('levels_foods',
                            {'n': level.targetFoods}),
                        style: TextStyle(
                          fontSize: 11,
                          color: p.textMuted,
                        ),
                      ),
                    ] else
                      Text(
                        L10n.t('levels_locked'),
                        style: TextStyle(
                          fontSize: 11,
                          color: p.textMuted.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}