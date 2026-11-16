import 'dart:ui';

import '../services/localization_service.dart';

class GamePalette {
  final String id;
  final Color bg,
      surface,
      surfaceAlt,
      border,
      grid,
      board,
      snakeHead,
      snakeTail,
      food,
      accent,
      textMuted,
      textPrimary,
      onPrimary;

  const GamePalette({
    required this.id,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.grid,
    required this.board,
    required this.snakeHead,
    required this.snakeTail,
    required this.food,
    required this.accent,
    required this.textMuted,
    required this.textPrimary,
    required this.onPrimary,
  });

  String get name => L10n.t('palette_${id}_name');
}

const neonPalette = GamePalette(
  id: 'neon',
  bg: Color(0xFF0B0F14),
  surface: Color(0xFF141B24),
  surfaceAlt: Color(0xFF1B2430),
  border: Color(0xFF22303F),
  grid: Color(0xFF16202B),
  board: Color(0xFF0F151D),
  snakeHead: Color(0xFF7BFFD0),
  snakeTail: Color(0xFF1E9E76),
  food: Color(0xFFFF6B8A),
  accent: Color(0xFF4CE0B3),
  textMuted: Color(0xFF6B7D91),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF06231B),
);

const sunsetPalette = GamePalette(
  id: 'sunset',
  bg: Color(0xFF160B14),
  surface: Color(0xFF231424),
  surfaceAlt: Color(0xFF2E1B30),
  border: Color(0xFF3D2643),
  grid: Color(0xFF2A1830),
  board: Color(0xFF1A0F1A),
  snakeHead: Color(0xFFFFB86B),
  snakeTail: Color(0xFFE8615C),
  food: Color(0xFFFF5CAB),
  accent: Color(0xFFFF8A5B),
  textMuted: Color(0xFFA28B9F),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF1A0A0A),
);

const cyberPalette = GamePalette(
  id: 'cyber',
  bg: Color(0xFF0A0B18),
  surface: Color(0xFF14162A),
  surfaceAlt: Color(0xFF1E2040),
  border: Color(0xFF2D2F5C),
  grid: Color(0xFF1A1C38),
  board: Color(0xFF0D0F22),
  snakeHead: Color(0xFF8A7BFF),
  snakeTail: Color(0xFF4D2FFF),
  food: Color(0xFF00F0FF),
  accent: Color(0xFF7B6AFF),
  textMuted: Color(0xFF7C7FA8),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF07031A),
);

const firePalette = GamePalette(
  id: 'fire',
  bg: Color(0xFF1A0808),
  surface: Color(0xFF2A1010),
  surfaceAlt: Color(0xFF3A1818),
  border: Color(0xFF4A2020),
  grid: Color(0xFF351515),
  board: Color(0xFF1F0A0A),
  snakeHead: Color(0xFFFFB347),
  snakeTail: Color(0xFFCC3300),
  food: Color(0xFFFFD700),
  accent: Color(0xFFFF6600),
  textMuted: Color(0xFFA07060),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF1A0808),
);

const forestPalette = GamePalette(
  id: 'forest',
  bg: Color(0xFF08140A),
  surface: Color(0xFF102010),
  surfaceAlt: Color(0xFF182818),
  border: Color(0xFF204028),
  grid: Color(0xFF142818),
  board: Color(0xFF0A1810),
  snakeHead: Color(0xFF7FFF7F),
  snakeTail: Color(0xFF1E7A1E),
  food: Color(0xFFFF6B8A),
  accent: Color(0xFF2ECC71),
  textMuted: Color(0xFF6B8F6B),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF08140A),
);

const icePalette = GamePalette(
  id: 'ice',
  bg: Color(0xFF081218),
  surface: Color(0xFF101F2A),
  surfaceAlt: Color(0xFF18283A),
  border: Color(0xFF204060),
  grid: Color(0xFF152A3A),
  board: Color(0xFF0A1520),
  snakeHead: Color(0xFFC0EFFF),
  snakeTail: Color(0xFF3070CC),
  food: Color(0xFFFF88CC),
  accent: Color(0xFF4FC3F7),
  textMuted: Color(0xFF7090A8),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF081218),
);

// 🌊 اقیانوس
const oceanPalette = GamePalette(
  id: 'ocean',
  bg: Color(0xFF04141C),
  surface: Color(0xFF0A2432),
  surfaceAlt: Color(0xFF0F3040),
  border: Color(0xFF1A4A5C),
  grid: Color(0xFF0D2830),
  board: Color(0xFF061A24),
  snakeHead: Color(0xFF00E5FF),
  snakeTail: Color(0xFF00838F),
  food: Color(0xFFFF6E40),
  accent: Color(0xFF00BCD4),
  textMuted: Color(0xFF6B8E99),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF04141C),
);

// ☢️ سمی
const toxicPalette = GamePalette(
  id: 'toxic',
  bg: Color(0xFF0A1408),
  surface: Color(0xFF0F1F0A),
  surfaceAlt: Color(0xFF142A0F),
  border: Color(0xFF1F3F14),
  grid: Color(0xFF15290F),
  board: Color(0xFF081008),
  snakeHead: Color(0xFF39FF14),
  snakeTail: Color(0xFF1B5E20),
  food: Color(0xFFFFFF00),
  accent: Color(0xFF76FF03),
  textMuted: Color(0xFF5A7D50),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF0A1408),
);

// 🍒 گیلاس
const cherryPalette = GamePalette(
  id: 'cherry',
  bg: Color(0xFF1A0510),
  surface: Color(0xFF260A18),
  surfaceAlt: Color(0xFF331022),
  border: Color(0xFF4A1A30),
  grid: Color(0xFF2A0A1C),
  board: Color(0xFF1A0510),
  snakeHead: Color(0xFFFF4081),
  snakeTail: Color(0xFF880E4F),
  food: Color(0xFFFF80AB),
  accent: Color(0xFFFF4081),
  textMuted: Color(0xFF996677),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF1A0510),
);

// 🌌 نیمه‌شب
const midnightPalette = GamePalette(
  id: 'midnight',
  bg: Color(0xFF080A1A),
  surface: Color(0xFF11142B),
  surfaceAlt: Color(0xFF1A1F3F),
  border: Color(0xFF2A3060),
  grid: Color(0xFF151A33),
  board: Color(0xFF0A0C1F),
  snakeHead: Color(0xFF7C4DFF),
  snakeTail: Color(0xFF311B92),
  food: Color(0xFFE040FB),
  accent: Color(0xFF7C4DFF),
  textMuted: Color(0xFF6E6E9E),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF080A1A),
);

// 👑 طلایی
const goldPalette = GamePalette(
  id: 'gold',
  bg: Color(0xFF0F0D08),
  surface: Color(0xFF1A1710),
  surfaceAlt: Color(0xFF26221A),
  border: Color(0xFF3D3520),
  grid: Color(0xFF1F1C12),
  board: Color(0xFF0D0B06),
  snakeHead: Color(0xFFFFD54F),
  snakeTail: Color(0xFF8D6E00),
  food: Color(0xFFFFF9C4),
  accent: Color(0xFFFFD700),
  textMuted: Color(0xFF8A7D50),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF0F0D08),
);

const portalsPalette = GamePalette(
  id: 'portals',
  bg: Color(0xFF0D0518),
  surface: Color(0xFF1A0D2E),
  surfaceAlt: Color(0xFF261540),
  border: Color(0xFF3D2660),
  grid: Color(0xFF201235),
  board: Color(0xFF0D0518),
  snakeHead: Color(0xFF00E5FF),
  snakeTail: Color(0xFF7C4DFF),
  food: Color(0xFFFFD700),
  accent: Color(0xFF7C4DFF),
  textMuted: Color(0xFF7E6BA8),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF0D0518),
);

// 🔴 قصر زمان
const timePalette = GamePalette(
  id: 'time',
  bg: Color(0xFF14060A),
  surface: Color(0xFF1F0A10),
  surfaceAlt: Color(0xFF2A1018),
  border: Color(0xFF3D1A20),
  grid: Color(0xFF261018),
  board: Color(0xFF14060A),
  snakeHead: Color(0xFFFF6B35),
  snakeTail: Color(0xFF8B0000),
  food: Color(0xFFFFD700),
  accent: Color(0xFFFF3D3D),
  textMuted: Color(0xFF8A6068),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF14060A),
);

// ── Stage 3: Level-Exclusive Themes ──
const championPalette = GamePalette(
  id: 'champion_theme',
  bg: Color(0xFF1A0E08),
  surface: Color(0xFF241410),
  surfaceAlt: Color(0xFF2E1C14),
  border: Color(0xFF4A3520),
  grid: Color(0xFF3A2414),
  board: Color(0xFF140A06),
  snakeHead: Color(0xFFFFD54F),
  snakeTail: Color(0xFFB8860B),
  food: Color(0xFFFFB300),
  accent: Color(0xFFFFB300),
  textMuted: Color(0xFFA88A60),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF1A0E08),
);

const marpechLegendPalette = GamePalette(
  id: 'marpech_legend_theme',
  bg: Color(0xFF0A0014),
  surface: Color(0xFF150022),
  surfaceAlt: Color(0xFF1F0030),
  border: Color(0xFF3D0060),
  grid: Color(0xFF220035),
  board: Color(0xFF080010),
  snakeHead: Color(0xFFFF00E5),
  snakeTail: Color(0xFF7C00A8),
  food: Color(0xFFFF00E5),
  accent: Color(0xFFFF00E5),
  textMuted: Color(0xFFA070B8),
  textPrimary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF0A0014),
);

// ☀️ پالت‌های روشن (جدا از پالت‌های تاریک)

// ☀️ پالت‌های روشن (جدا از پالت‌های تاریک)

// 🌿 Mint: سفید مایل به خاکستری با آکسنت نعنایی
const lightMintPalette = GamePalette(
  id: 'light_mint',
  bg: Color(0xFFF4F7F6),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFE9F2EF),
  border: Color(0xFF9FC2B6),
  grid: Color(0xFFC5DDD5),
  board: Color(0xFFCFE6DE),
  snakeHead: Color(0xFF0A7D60),
  snakeTail: Color(0xFF3DB996),
  food: Color(0xFFE63956),
  accent: Color(0xFF0E9F7A),
  textMuted: Color(0xFF5E7068),
  textPrimary: Color(0xFF13201C),
  onPrimary: Color(0xFFFFFFFF),
);

// 🍊 Cream: کرم ملایم با آکسنت نارنجی گرم
const lightCreamPalette = GamePalette(
  id: 'light_cream',
  bg: Color(0xFFFBF6EC),
  surface: Color(0xFFFFFDF8),
  surfaceAlt: Color(0xFFF5EBD9),
  border: Color(0xFFA9864E),
  grid: Color(0xFFC4A46E),
  board: Color(0xFFD4B88A),
  snakeHead: Color(0xFFD9611A),
  snakeTail: Color(0xFFB8500F),
  food: Color(0xFFC62828),
  accent: Color(0xFFD9611A),
  textMuted: Color(0xFF7A6650),
  textPrimary: Color(0xFF2B2016),
  onPrimary: Color(0xFFFFFFFF),
);

// 🩵 Slate: خاکستری روشن با آکسنت آبی
const lightSlatePalette = GamePalette(
  id: 'light_slate',
  bg: Color(0xFFEEF1F5),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFE3E8EF),
  border: Color(0xFF8D9CB0),
  grid: Color(0xFFBFCAD8),
  board: Color(0xFFCBD5E1),
  snakeHead: Color(0xFF1D4ED8),
  snakeTail: Color(0xFF5B8DE0),
  food: Color(0xFFE11D48),
  accent: Color(0xFF2563EB),
  textMuted: Color(0xFF55657A),
  textPrimary: Color(0xFF0F172A),
  onPrimary: Color(0xFFFFFFFF),
);

/// لیست پالت‌های روشن (پیش‌فرض: اولی)
const lightPalettes = [
  lightMintPalette,
  lightCreamPalette,
  lightSlatePalette,
];

const palettes = [
  neonPalette,
  sunsetPalette,
  cyberPalette,
  firePalette,
  forestPalette,
  icePalette,
  oceanPalette,
  toxicPalette,
  cherryPalette,
  midnightPalette,
  goldPalette,
  portalsPalette,
  timePalette,
  // ── Stage 3: به انتها اضافه شده — index حفظ می‌شود ──
  championPalette, // index 13
  marpechLegendPalette, // index 14
];
