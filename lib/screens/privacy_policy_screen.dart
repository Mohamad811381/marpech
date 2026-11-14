// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/game_palette.dart';
import '../services/localization_service.dart';

/// ⚠️ قبل از انتشار، این ایمیل رو با ایمیل واقعی خودت عوض کن
const String kPrivacyContactEmail = 'support@marpech.app';

class PrivacyPolicyScreen extends StatelessWidget {
  final GamePalette palette;
  const PrivacyPolicyScreen({super.key, required this.palette});

  GamePalette get p => palette;

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
                  _lastUpdatedCard(),
                  const SizedBox(height: 14),
                  _sectionCard(1),
                  const SizedBox(height: 10),
                  _sectionCard(2),
                  const SizedBox(height: 10),
                  _sectionCard(3),
                  const SizedBox(height: 10),
                  _sectionCard(4),
                  const SizedBox(height: 10),
                  _sectionCard(5),
                  const SizedBox(height: 10),
                  _sectionCard(6),
                  const SizedBox(height: 10),
                  _sectionCard(7),
                  const SizedBox(height: 10),
                  _sectionCard(8, isLast: true),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.t('privacy_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  L10n.t('privacy_subtitle'),
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.privacy_tip_rounded, color: p.accent, size: 26),
        ],
      ),
    );
  }

  Widget _lastUpdatedCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: p.textMuted),
          const SizedBox(width: 6),
          Text(
            L10n.t('privacy_last_updated'),
            style: TextStyle(fontSize: 11, color: p.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(int index, {bool isLast = false}) {
    final title = L10n.t('privacy_section_${index}_title');
    final body = L10n.t('privacy_section_${index}_body');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: p.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: p.accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: p.textMuted,
            ),
          ),
          if (index == 8) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: p.accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_rounded, size: 16, color: p.accent),
                  const SizedBox(width: 8),
                  SelectableText(
                    kPrivacyContactEmail,
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
        ],
      ),
    );
  }
}
