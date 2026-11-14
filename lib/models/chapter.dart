import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class Chapter {
  final int id;
  final String emoji;
  final Color accentColor;
  final int startLevelId;
  final int endLevelId;

  const Chapter({
    required this.id,
    required this.emoji,
    required this.accentColor,
    required this.startLevelId,
    required this.endLevelId,
  });

  String get name => L10n.t('chapter_${id}_name');
  String get desc => L10n.t('chapter_${id}_desc');
  int get levelCount => endLevelId - startLevelId + 1;
}