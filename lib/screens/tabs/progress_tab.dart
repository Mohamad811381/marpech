// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/game_palette.dart';
import '../../services/localization_service.dart';
import '../stats_screen.dart';
import '../achievements_screen.dart';
import '../missions_screen.dart';
import '../player_progress_tab.dart';

class ProgressTab extends StatefulWidget {
  final GamePalette palette;
  const ProgressTab({super.key, required this.palette});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GamePalette get p => widget.palette;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // هدر
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Icon(Icons.track_changes_rounded, color: p.accent, size: 22),
              const SizedBox(width: 8),
              Text(
                L10n.t('nav_progress'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // تب‌ها
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            tabs: [
              Tab(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.trending_up_rounded, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        L10n.t('progress_tab_player'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.insights_rounded, size: 14),
                    const SizedBox(width: 4),
                    Text(L10n.t('progress_tab_stats')),
                  ],
                ),
              ),
              Tab(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.military_tech_rounded, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        L10n.t('progress_tab_missions'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        L10n.t('progress_tab_achievements'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              PlayerProgressTab(palette: p),
              StatsScreen(palette: p, embedded: true),
              MissionsScreen(palette: p, embedded: true),
              AchievementsScreen(palette: p, embedded: true),
            ],
          ),
        ),
      ],
    );
  }
}
