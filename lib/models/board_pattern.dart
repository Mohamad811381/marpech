// ignore_for_file: deprecated_member_use, unused_import, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import '../services/localization_service.dart';

enum BoardPattern {
  none('none'),
  galaxy('galaxy'),
  spiral('spiral'),
  stars('stars'),
  checkerboard('checkerboard'),
  gridPlus('grid_plus'),
  waves('waves'),
  crystal('crystal'),
  petals('petals'),
  legendPattern('legend_pattern');

  final String id;
  const BoardPattern(this.id);

  String get name => L10n.t('pattern_${id}_name');
  String get desc => L10n.t('pattern_${id}_desc');

  static BoardPattern fromId(String? id) => BoardPattern.values
      .firstWhere((p) => p.id == id, orElse: () => BoardPattern.none);
}

enum PatternIntensity {
  subtle('subtle', 0.4),
  medium('medium', 1.0),
  bold('bold', 1.7);

  final String id;
  final double multiplier;
  const PatternIntensity(this.id, this.multiplier);

  String get label => L10n.t('pattern_intensity_${id}');

  static PatternIntensity fromId(String? id) => PatternIntensity.values
      .firstWhere((p) => p.id == id, orElse: () => PatternIntensity.bold);
}
