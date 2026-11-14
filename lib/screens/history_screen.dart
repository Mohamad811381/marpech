// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/game_history_entry.dart';
import '../models/game_palette.dart';
import '../services/audio_service.dart';
import '../services/history_service.dart';
import '../services/localization_service.dart';

class HistoryScreen extends StatefulWidget {
  final GamePalette palette;
  const HistoryScreen({super.key, required this.palette});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _audio = AudioService();
  List<GameHistoryEntry>? _entries;

  GamePalette get p => widget.palette;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await HistoryService.getAll();
    if (!mounted) return;
    setState(() => _entries = e);
  }

  Future<void> _clear() async {
    await _audio.playSfx(Sfx.button);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(
          L10n.t('history_clear_btn'),
          style: TextStyle(color: p.textPrimary),
        ),
        content: Text(
          L10n.t('history_clear_confirm'),
          style: TextStyle(color: p.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              L10n.t('cancel'),
              style: TextStyle(color: p.accent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              L10n.t('delete'),
              style: TextStyle(color: p.food),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await HistoryService.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(entries?.length ?? 0),
            if (entries == null)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: p.accent),
                ),
              )
            else if (entries.isEmpty)
              Expanded(child: _emptyState())
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: entries.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    if (i == entries.length) return _clearButton();
                    return _entryCard(entries[i]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(int count) {
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
                  L10n.t('history_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  count > 0
                      ? L10n.tf('history_sub', {'n': count})
                      : L10n.t('history_empty_title'),
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.history_rounded, color: p.accent, size: 26),
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off_rounded,
              size: 64, color: p.textMuted.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text(
            L10n.t('history_empty_title'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: p.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            L10n.t('history_empty_sub'),
            style: TextStyle(
                fontSize: 12, color: p.textMuted.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _entryCard(GameHistoryEntry e) {
    final timeStr = _relativeTime(e.timestamp);
    final modeIcon = e.mode == GameMode.free
        ? Icons.sports_esports_rounded
        : e.mode == GameMode.timeAttack
            ? Icons.timer_rounded
            : Icons.map_rounded;
    final modeColor = e.mode == GameMode.free
        ? p.accent
        : e.mode == GameMode.timeAttack
            ? const Color(0xFFFF8A5B)
            : const Color(0xFF8A7BFF);

    final title = e.mode == GameMode.level
        ? '${L10n.tf('history_level', {'n': e.levelId ?? '?'})}'
            '${e.won ? ' ✓' : ''}'
        : e.mode.label;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: e.wasNewRecord ? p.food.withOpacity(0.5) : p.border,
          width: e.wasNewRecord ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: modeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(modeIcon, color: modeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (e.wasNewRecord) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: p.food.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '🏆',
                          style: TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 3,
                  children: [
                    _tinyChip(L10n.tf('history_score', {'n': e.score})),
                    _tinyChip('${e.foodsEaten} 🍎'),
                    _tinyChip(
                        L10n.tf('history_length', {'n': e.snakeLength})),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: p.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                e.difficulty.label,
                style: TextStyle(
                  fontSize: 9,
                  color: p.textMuted.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tinyChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: p.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _clearButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton.icon(
          onPressed: _clear,
          icon: Icon(Icons.delete_outline_rounded,
              color: p.food, size: 18),
          label: Text(
            L10n.t('history_clear_btn'),
            style: TextStyle(
              color: p.food,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: p.food.withOpacity(0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tDay = DateTime(t.year, t.month, t.day);
    final diff = today.difference(tDay).inDays;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');

    if (diff == 0) return L10n.tf('history_today', {'time': '$hh:$mm'});
    if (diff == 1) return L10n.tf('history_yesterday', {'time': '$hh:$mm'});
    if (diff < 7) return L10n.tf('history_days_ago', {'n': diff});
    return '${t.year}/${t.month.toString().padLeft(2, '0')}/${t.day.toString().padLeft(2, '0')}';
  }
}