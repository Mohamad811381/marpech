// ignore_for_file: unused_field, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:marpech/models/chapter.dart';
import '../models/difficulty.dart';
import '../models/game_palette.dart';
import '../services/audio_service.dart';
import '../services/levels_service.dart';
import '../services/localization_service.dart';
import 'level_select_screen.dart';

class ChaptersScreen extends StatefulWidget {
  final GamePalette palette;
  final Difficulty difficulty;

  const ChaptersScreen({
    super.key,
    required this.palette,
    required this.difficulty,
  });

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  final _audio = AudioService();
  Set<int> _completed = {};
  int _highestUnlocked = 1;
  bool _loaded = false;

  GamePalette get p => widget.palette;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await LevelsService.getCompleted();
    final h = await LevelsService.getHighestUnlocked();
    if (!mounted) return;
    setState(() {
      _completed = c;
      _highestUnlocked = h;
      _loaded = true;
    });
  }

  int _completedInChapter(int startId, int endId) {
    return _completed.where((id) => id >= startId && id <= endId).length;
  }

  Future<void> _openChapter(int chapterId) async {
    final chapter = LevelsService.getChapter(chapterId);
    if (chapter == null) return;
    if (!LevelsService.isChapterAvailable(chapter)) return;

    await _audio.playSfx(Sfx.button);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LevelSelectScreen(
          palette: p,
          difficulty: widget.difficulty,
          chapter: chapter,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final totalCompleted = _completed.length;
    final totalLevels = LevelsService.all.length;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(totalCompleted, totalLevels),
            if (!_loaded)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: p.accent),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    for (final c in LevelsService.chapters)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _chapterCard(c),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(int completed, int total) {
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
                Text(
                  L10n.t('chapters_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  L10n.tf('chapters_sub', {'n': completed, 'm': total}),
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: p.accent, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$completed/$total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
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
          child: Icon(Icons.arrow_back_rounded, color: p.accent, size: 22),
        ),
      ),
    );
  }

  Widget _chapterCard(Chapter chapter) {
    final isAvailable = LevelsService.isChapterAvailable(chapter);
    final doneInChapter =
        _completedInChapter(chapter.startLevelId, chapter.endLevelId);
    final totalInChapter = chapter.levelCount;
    final progress = totalInChapter == 0 ? 0.0 : doneInChapter / totalInChapter;
    final allDone = doneInChapter == totalInChapter;

    final accent = chapter.accentColor;

    return GestureDetector(
      onTap: isAvailable ? () => _openChapter(chapter.id) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isAvailable
              ? LinearGradient(
                  colors: [
                    accent.withOpacity(0.12),
                    p.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isAvailable ? null : p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAvailable
                ? accent.withOpacity(0.4)
                : p.border.withOpacity(0.4),
            width: isAvailable ? 1.5 : 1,
          ),
          boxShadow: isAvailable
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: emoji + number + name + lock/check
            Row(
              children: [
                // Emoji circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color:
                        isAvailable ? accent.withOpacity(0.18) : p.surfaceAlt,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAvailable ? accent.withOpacity(0.5) : p.border,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    chapter.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'فصل ${chapter.id}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isAvailable
                                  ? accent
                                  : p.textMuted.withOpacity(0.6),
                            ),
                          ),
                          if (!isAvailable) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.lock_rounded,
                              size: 12,
                              color: p.textMuted.withOpacity(0.6),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chapter.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isAvailable
                              ? p.textPrimary
                              : p.textMuted.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAvailable && allDone)
                  Icon(
                    Icons.verified_rounded,
                    color: accent,
                    size: 28,
                  ),
                if (isAvailable && !allDone)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: p.textMuted,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              chapter.desc,
              style: TextStyle(
                fontSize: 12,
                color: isAvailable ? p.textMuted : p.textMuted.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 14),

            // Progress
            if (isAvailable) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: p.border,
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    L10n.tf('chapters_chapter_progress', {
                      'n': doneInChapter,
                      'm': totalInChapter,
                    }),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: p.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, color: p.textMuted, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      L10n.t('chapters_coming_soon'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
