// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/game_palette.dart';
import '../models/mission.dart';
import '../services/audio_service.dart';
import '../services/daily_reward_service.dart';
import '../services/localization_service.dart';
import '../services/missions_service.dart';

class MissionsScreen extends StatefulWidget {
  final GamePalette palette;
  final bool embedded;

  const MissionsScreen({
    super.key,
    required this.palette,
    this.embedded = false,
  });

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen>
    with SingleTickerProviderStateMixin {
  final _audio = AudioService();
  late TabController _tabController;
  Map<MissionTab, List<MissionProgress>> _byTab = {};
  int _coins = 0;
  bool _loaded = false;

  GamePalette get p => widget.palette;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: MissionTab.values.length,
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
      MissionsService.getVisibleProgress(),
      DailyRewardService.getCoins(),
    ]);
    if (!mounted) return;
    final visible = results[0] as List<MissionProgress>;
    final coins = results[1] as int;
    setState(() {
      _byTab = {
        for (final t in MissionTab.values)
          t: visible.where((p) => p.mission.tab == t).toList(),
      };
      _coins = coins;
      _loaded = true;
    });
  }

  Future<void> _claim(MissionProgress prog) async {
    await _audio.playSfx(Sfx.newRecord);
    final reward = await MissionsService.claimNextStage(prog.mission.id);
    if (reward > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: p.surface,
          content: Text(
            L10n.tf('missions_toast', {'n': reward}),
            style: TextStyle(color: p.textPrimary),
          ),
        ),
      );
    }
    await _load();
  }

  int get _totalRemaining {
    return _byTab.values.fold(0, (a, b) => a + b.length);
  }

  @override
  Widget build(BuildContext context) {
    // محتوای مشترک (بدون Scaffold)
    final content = Column(
      children: [
        if (!_loaded)
          Expanded(
            child: Center(
              child: CircularProgressIndicator(color: p.accent),
            ),
          )
        else if (_totalRemaining == 0)
          Expanded(child: _allDoneState())
        else ...[
          _tabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: MissionTab.values.map((tab) {
                final list = _byTab[tab] ?? [];
                if (list.isEmpty) {
                  return _emptyTabState(tab);
                }
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  children: list.map(_missionCard).toList(),
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
            _topBar(),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  // ---------- نوار بالا (فقط standalone) ----------

  Widget _topBar() {
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
                  L10n.t('missions_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  L10n.tf('missions_remaining_sub', {'n': _totalRemaining}),
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
                Icon(Icons.monetization_on_rounded, color: p.food, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_coins',
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
        tabs: MissionTab.values.map((tab) {
          final count = _byTab[tab]?.length ?? 0;
          return Tab(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tab.icon, size: 14),
                const SizedBox(width: 4),
                Text(tab.label),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: tab.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: tab.color,
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

  // ---------- حالت‌های خالی ----------

  Widget _emptyTabState(MissionTab tab) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 64, color: tab.color.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            L10n.t('missions_tab_empty'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: p.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _allDoneState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            L10n.t('missions_all_done'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            L10n.t('missions_all_done_sub'),
            style: TextStyle(fontSize: 12, color: p.textMuted),
          ),
        ],
      ),
    );
  }

  // ---------- کارت ماموریت ----------

  Widget _missionCard(MissionProgress prog) {
    final m = prog.mission;
    final canClaim = prog.canClaimCurrent;
    final stageIdx = prog.claimedStages;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canClaim ? m.color.withOpacity(0.7) : p.border,
          width: canClaim ? 2 : 1,
        ),
        boxShadow: canClaim
            ? [
                BoxShadow(
                  color: m.color.withOpacity(0.25),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: m.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(m.icon, color: m.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.description,
                      style: TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: p.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  L10n.tf('missions_stage', {
                    'n': stageIdx + 1,
                    'm': prog.totalStages,
                  }),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: p.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: prog.ratio,
                    minHeight: 6,
                    backgroundColor: p.border,
                    valueColor: AlwaysStoppedAnimation(m.color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${prog.displayValue}/${prog.displayTarget}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: m.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.monetization_on_rounded, color: p.food, size: 14),
              const SizedBox(width: 4),
              Text(
                L10n.tf('missions_reward', {'n': prog.currentStage!.reward}),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: p.food,
                ),
              ),
              const Spacer(),
              if (canClaim)
                Material(
                  color: m.color,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _claim(prog),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      child: Text(
                        L10n.t('claim'),
                        style: TextStyle(
                          color: p.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
