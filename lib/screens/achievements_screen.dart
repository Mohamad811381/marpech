// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/game_palette.dart';
import '../services/achievements_service.dart';
import '../services/localization_service.dart';
import '../services/storage_service.dart';

class AchievementsScreen extends StatefulWidget {
  final GamePalette palette;
  final bool embedded;

  const AchievementsScreen({
    super.key,
    required this.palette,
    this.embedded = false,
  });

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AchievementStats? _stats;
  Set<String> _unlocked = {};
  bool _loaded = false;
  Map<AchievementCategory, List<Achievement>> _categorized = const {};
  Map<AchievementCategory, int> _unlockedByCategory = const {};

  GamePalette get p => widget.palette;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AchievementCategory.values.length,
      vsync: this,
    );
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      AchievementsService.getStats(),
      StorageService.getUnlockedAchievements(),
    ]);
    if (!mounted) return;
    final stats = results[0] as AchievementStats;
    final unlocked = results[1] as Set<String>;
    final categorized = <AchievementCategory, List<Achievement>>{
      for (final cat in AchievementCategory.values)
        cat: allAchievements.where((a) => a.category == cat).toList(),
    };
    final unlockedByCategory = <AchievementCategory, int>{
      for (final cat in AchievementCategory.values)
        cat: categorized[cat]!.where((a) => unlocked.contains(a.id)).length,
    };
    setState(() {
      _stats = stats;
      _unlocked = unlocked;
      _categorized = categorized;
      _unlockedByCategory = unlockedByCategory;
      _loaded = true;
    });
  }

  List<Achievement> _byCategory(AchievementCategory cat) =>
      _categorized[cat] ?? const [];

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final total = allAchievements.length;
    final done = _unlocked.length;

    // محتوای مشترک (بدون Scaffold)
    final content = Column(
      children: [
        if (!_loaded)
          Expanded(
            child: Center(
              child: CircularProgressIndicator(color: p.accent),
            ),
          )
        else ...[
          _tabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: AchievementCategory.values.map((cat) {
                final list = _byCategory(cat);
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final a = list[i];
                    final isUnlocked = _unlocked.contains(a.id);
                    return _achievementTile(a, stats!, isUnlocked);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );

    // حالت embedded: فقط محتوا
    if (widget.embedded) {
      return content;
    }

    // حالت standalone: با Scaffold و top bar
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(done, total),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  // ---------- نوار بالا (فقط standalone) ----------

  Widget _topBar(int done, int total) {
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
                  L10n.t('achievements_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  L10n.tf('achievements_sub', {'n': done, 'm': total}),
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
                Icon(Icons.emoji_events_rounded, color: p.food, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$done/$total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.food,
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

  // ---------- تب‌بار ----------

  Widget _tabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: p.accent.withOpacity(0.2),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: p.accent,
        unselectedLabelColor: p.textMuted,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        tabs: AchievementCategory.values.map((cat) {
          final unlockedInCat = _unlockedByCategory[cat] ?? 0;
          return Tab(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat.icon, size: 14),
                const SizedBox(width: 4),
                Text(cat.label),
                if (unlockedInCat > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$unlockedInCat',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: cat.color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------- کارت دستاورد ----------

  Widget _achievementTile(
      Achievement a, AchievementStats stats, bool isUnlocked) {
    final progress = a.progress(stats).clamp(0, a.target);
    final ratio = a.target == 0 ? 0.0 : progress / a.target;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked ? p.surface : p.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? a.color.withOpacity(0.5) : p.border,
          width: isUnlocked ? 1.5 : 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: a.color.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isUnlocked ? a.color.withOpacity(0.15) : p.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked ? a.color.withOpacity(0.6) : p.border,
                width: 1.5,
              ),
            ),
            child: Icon(
              isUnlocked ? a.icon : Icons.lock_rounded,
              color: isUnlocked ? a.color : p.textMuted,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        a.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isUnlocked ? p.textPrimary : p.textMuted,
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      Icon(Icons.check_circle_rounded,
                          color: a.color, size: 20),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  a.description,
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 5,
                          backgroundColor: p.border,
                          valueColor: AlwaysStoppedAnimation(
                            isUnlocked ? a.color : p.accent.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$progress/${a.target}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isUnlocked ? a.color : p.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
