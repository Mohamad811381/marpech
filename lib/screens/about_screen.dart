// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/game_palette.dart';
import '../services/localization_service.dart';
import '../services/levels_service.dart';
import '../services/storage_service.dart';
import 'privacy_policy_screen.dart';
import 'winner_screen.dart';

class AboutScreen extends StatefulWidget {
  final GamePalette palette;
  const AboutScreen({super.key, required this.palette});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  GamePalette get p => widget.palette;

  int _gamesPlayed = 0;
  int _levelsCompleted = 0;
  int _longestSnake = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final games = await StorageService.getGamesPlayed();
    final completed = await LevelsService.getCompleted();
    final longest = await StorageService.getLongestSnake();
    if (!mounted) return;
    setState(() {
      _gamesPlayed = games;
      _levelsCompleted = completed.length;
      _longestSnake = longest;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _heroCard(),
                  const SizedBox(height: 16),
                  _statsCard(),
                  const SizedBox(height: 16),
                  _featuresCard(),
                  const SizedBox(height: 16),
                  _infoCard(),
                  const SizedBox(height: 16),
                  _linksCard(context),
                  const SizedBox(height: 20),
                  _footer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- نوار بالا ----------

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Material(
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
                child:
                    Icon(Icons.arrow_back_rounded, color: p.accent, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              L10n.t('about_title'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
          ),
          Icon(Icons.info_rounded, color: p.accent, size: 26),
        ],
      ),
    );
  }

  // ---------- کارت هدر (لوگو + نام + نسخه) ----------

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            p.accent.withOpacity(0.15),
            p.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.accent.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: p.accent.withOpacity(0.10),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.surface,
              border: Border.all(color: p.accent.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: p.accent.withOpacity(0.30),
                  blurRadius: 30,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(Icons.gesture, size: 56, color: p.accent),
          ),
          const SizedBox(height: 16),
          Text(
            L10n.t('app_name'),
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            L10n.t('app_tagline'),
            style: TextStyle(fontSize: 13, color: p.textMuted),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_offer_rounded, size: 12, color: p.textMuted),
                const SizedBox(width: 6),
                Text(
                  '${L10n.t('about_version')} 1.0.0',
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
      ),
    );
  }

  // ---------- کارت آمار بازیکن ----------

  Widget _statsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 16, color: p.accent),
              const SizedBox(width: 6),
              Text(
                L10n.t('about_your_stats'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  icon: Icons.sports_esports_rounded,
                  value: '$_gamesPlayed',
                  label: L10n.t('about_stat_games'),
                  color: const Color(0xFF00F0FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  icon: Icons.map_rounded,
                  value: '$_levelsCompleted',
                  label: L10n.t('about_stat_levels'),
                  color: p.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  icon: Icons.straighten_rounded,
                  value: '$_longestSnake',
                  label: L10n.t('about_stat_longest'),
                  color: const Color(0xFF8A7BFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: p.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- کارت ویژگی‌ها ----------

  Widget _featuresCard() {
    final features = [
      (Icons.map_rounded, L10n.t('about_feature_levels'), p.accent),
      (
        Icons.timer_rounded,
        L10n.t('about_feature_timed'),
        const Color(0xFFFF8A5B)
      ),
      (
        Icons.all_inclusive_rounded,
        L10n.t('about_feature_portals'),
        const Color(0xFF7C4DFF)
      ),
      (
        Icons.local_fire_department_rounded,
        L10n.t('about_feature_time'),
        const Color(0xFFFF3D3D)
      ),
      (
        Icons.palette_rounded,
        L10n.t('about_feature_themes'),
        const Color(0xFFFFD700)
      ),
      (
        Icons.emoji_events_rounded,
        L10n.t('about_feature_achievements'),
        p.food
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, size: 16, color: p.food),
              const SizedBox(width: 6),
              Text(
                L10n.t('about_features'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map((f) {
            final (icon, label, color) = f;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.check_rounded, size: 16, color: p.accent),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------- کارت اطلاعات (سازنده، زبان، ...) ----------

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.code_rounded,
            label: L10n.t('about_built_with'),
            value: 'Flutter',
            color: const Color(0xFF4CE0B3),
          ),
          Divider(color: p.border.withOpacity(0.4), height: 20),
          _infoRow(
            icon: Icons.translate_rounded,
            label: L10n.t('about_languages'),
            value: 'فارسی • English',
            color: const Color(0xFF00F0FF),
          ),
          Divider(color: p.border.withOpacity(0.4), height: 20),
          _infoRow(
            icon: Icons.cloud_off_rounded,
            label: L10n.t('about_offline'),
            value: L10n.t('about_offline_value'),
            color: const Color(0xFF8A7BFF),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
          ),
        ),
      ],
    );
  }

  // ---------- کارت لینک‌ها ----------

  Widget _linksCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          _linkRow(
            context,
            icon: Icons.privacy_tip_rounded,
            label: L10n.t('drawer_privacy'),
            color: p.accent,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PrivacyPolicyScreen(palette: p),
                ),
              );
            },
          ),
          _linkRow(
            context,
            icon: Icons.celebration_rounded,
            label: '🏆 تست Winner (موقت)',
            color: const Color(0xFFFFD700),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WinnerScreen(palette: p),
                ),
              );
            },
          ),
          Divider(color: p.border.withOpacity(0.4), height: 1, indent: 52),
          Divider(color: p.border.withOpacity(0.4), height: 1, indent: 52),
          _linkRow(
            context,
            icon: Icons.email_rounded,
            label: L10n.t('about_contact'),
            color: const Color(0xFFFFD700),
            trailing: kPrivacyContactEmail,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: p.surface,
                  title: Text(
                    L10n.t('about_contact'),
                    style: TextStyle(color: p.textPrimary),
                  ),
                  content: SelectableText(
                    kPrivacyContactEmail,
                    style: TextStyle(color: p.accent),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        L10n.t('ok'),
                        style: TextStyle(color: p.accent),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _linkRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) ...[
                Flexible(
                  child: Text(
                    trailing,
                    style: TextStyle(
                      fontSize: 10,
                      color: p.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: p.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- پاورقی ----------

  Widget _footer() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              L10n.t('about_made_with'),
              style: TextStyle(fontSize: 12, color: p.textMuted),
            ),
            const SizedBox(width: 4),
            Icon(Icons.favorite_rounded, color: p.food, size: 14),
            const SizedBox(width: 4),
            Text(
              L10n.t('about_made_by'),
              style: TextStyle(fontSize: 12, color: p.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '© 2026 ${L10n.t('app_name')}',
          style: TextStyle(
            fontSize: 10,
            color: p.textMuted.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
