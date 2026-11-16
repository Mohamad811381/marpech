// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:marpech/services/theme_service.dart';
import '../models/game_palette.dart';
import '../services/audio_service.dart';
import '../services/daily_reward_service.dart';
import '../services/localization_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/daily_reward_dialog.dart';
import '../services/player_progression_service.dart';
import '../widgets/level_up_dialog.dart';
import 'settings_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/progress_tab.dart';
import 'tabs/daily_tab.dart';
import 'tabs/shop_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _homeReloadToken = 0; // ← جدید
  bool _muted = false;
  bool _loaded = false;

  final _audio = AudioService();
  bool _isShowingLevelUpDialog = false;
  bool _isLevelUpDialogScheduled = false;
  bool _isShowingRewardDialog = false;
  bool _pendingRewardDialog = false;

  bool get _isAnyDialogShowing =>
      _isShowingLevelUpDialog || _isShowingRewardDialog;
  GamePalette _palette = neonPalette;

  @override
  void initState() {
    super.initState();
    PlayerProgressionService.pendingLevelUps.addListener(_onProgressionChanged);
    PlayerProgressionService.dialogSafe.addListener(_onProgressionChanged);
    ThemeService.mode.addListener(_onThemeChanged);
    ThemeService.darkPalette.addListener(_onThemeChanged);
    _load();
  }

  @override
  void dispose() {
    PlayerProgressionService.pendingLevelUps
        .removeListener(_onProgressionChanged);
    PlayerProgressionService.dialogSafe.removeListener(_onProgressionChanged);
    ThemeService.mode.removeListener(_onThemeChanged);
    ThemeService.darkPalette.removeListener(_onThemeChanged);
    _isLevelUpDialogScheduled = false;
    _isShowingLevelUpDialog = false;
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    await SettingsService.load();
    final s = SettingsService.current;

    if (!mounted) return;
    setState(() {
      _muted = !(s.sfx || s.music);
      _loaded = true;
    });

    // 🎁 نمایش خودکار پاداش روزانه
    if (await DailyRewardService.shouldAutoShow()) {
      await DailyRewardService.markAutoShown();
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _showRewardDialog();
      });
    }
  }

  Future<void> _showRewardDialog() async {
    // Stage 4 fix: اگر دیالوگ دیگری باز است، reward را به تعویق بینداز
    if (_isAnyDialogShowing) {
      _pendingRewardDialog = true;
      return;
    }
    final status = await DailyRewardService.getStatus();
    if (!mounted) return;
    _isShowingRewardDialog = true;
    _pendingRewardDialog = false;
    try {
      final result = await showDialog<int>(
        context: context,
        barrierDismissible: true,
        builder: (_) => DailyRewardDialog(palette: _palette, status: status),
      );
      if (result != null && result > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _palette.surface,
            content: Text(
              L10n.tf('menu_reward_toast', {'n': result}),
              style: TextStyle(color: _palette.textPrimary),
            ),
          ),
        );
      }
    } finally {
      _isShowingRewardDialog = false;
      // بعد از بستن reward، چک کن اگر level-up در انتظار است
      _onProgressionChanged();
    }
  }

  Future<void> _reloadPalette() async {
    if (mounted) setState(() {});
  }

  void _openProgressTab() {
    setState(() => _currentIndex = 1);
  }

  Future<void> _toggleMute() async {
    final s = SettingsService.current;
    final allOn = s.sfx && s.music;
    final newS = s.copyWith(sfx: !allOn, music: !allOn);
    await SettingsService.save(newS);
    await _audio.onSettingsChanged();
    if (!allOn) await _audio.playSfx(Sfx.button);
    if (mounted) setState(() => _muted = allOn);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(palette: _palette),
      ),
    );
    await _reloadPalette();
    await SettingsService.load();
    final s = SettingsService.current;
    if (mounted) {
      setState(() {
        _muted = !(s.sfx || s.music);
        _homeReloadToken++; // ← HomeTab رو مجبور به reload می‌کنه
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _palette = ThemeService.resolve(context);

    if (!_loaded) {
      return Scaffold(
        backgroundColor: _palette.bg,
        body: Center(
          child: CircularProgressIndicator(color: _palette.accent),
        ),
      );
    }

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: _palette.bg,
        drawer: AppDrawer(
          palette: _palette,
          muted: _muted,
          onToggleMute: _toggleMute,
          onOpenSettings: _openSettings,
          onPaletteChanged: _reloadPalette,
        ),
        body: SafeArea(
          bottom: false,
          child: _buildBody(),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return HomeTab(
          key: ValueKey('home_$_homeReloadToken'), // ← جدید
          palette: _palette,
          onPaletteChanged: _reloadPalette,
          onLevelBadgeTap: _openProgressTab,
        );
      case 1:
        return ProgressTab(palette: _palette);
      case 2:
        return DailyTab(palette: _palette);
      case 3:
        return ShopTab(
          palette: _palette,
          onPaletteChanged: _reloadPalette,
        );
      default:
        return HomeTab(
          key: ValueKey('home_$_homeReloadToken'), // ← جدید
          palette: _palette,
          onPaletteChanged: _reloadPalette,
          onLevelBadgeTap: _openProgressTab,
        );
    }
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      backgroundColor: _palette.surface,
      indicatorColor: _palette.accent.withOpacity(0.20),
      surfaceTintColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 68,
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: _palette.textMuted),
          selectedIcon: Icon(Icons.home_rounded, color: _palette.accent),
          label: L10n.t('nav_home'),
        ),
        NavigationDestination(
          icon: Icon(Icons.track_changes_outlined, color: _palette.textMuted),
          selectedIcon:
              Icon(Icons.track_changes_rounded, color: _palette.accent),
          label: L10n.t('nav_progress'),
        ),
        NavigationDestination(
          icon: Icon(Icons.card_giftcard_outlined, color: _palette.textMuted),
          selectedIcon:
              Icon(Icons.card_giftcard_rounded, color: _palette.accent),
          label: L10n.t('nav_daily'),
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined, color: _palette.textMuted),
          selectedIcon: Icon(Icons.storefront_rounded, color: _palette.accent),
          label: L10n.t('nav_shop'),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Stage 4: Level-up dialog coordinator
  // ══════════════════════════════════════════════════════════════

  void _onProgressionChanged() {
    if (!mounted) return;
    if (_isShowingLevelUpDialog) return;
    if (_isShowingRewardDialog) return; // ← جدید
    if (_isLevelUpDialogScheduled) return;
    if (!mounted) return;
    if (_isShowingLevelUpDialog) return;
    if (_isLevelUpDialogScheduled) return;
    if (!PlayerProgressionService.dialogSafe.value) return;
    if (PlayerProgressionService.pendingLevelUps.value.isEmpty) return;

    _isLevelUpDialogScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isLevelUpDialogScheduled = false;
      if (!mounted) return;
      if (_isShowingLevelUpDialog) return;
      if (!PlayerProgressionService.dialogSafe.value) return;
      if (PlayerProgressionService.pendingLevelUps.value.isEmpty) return;
      _showNextLevelUpDialog();
    });

    // تضمین اجرای callback حتی در idle state (بدون انیمیشن فعال)
    if (!WidgetsBinding.instance.hasScheduledFrame) {
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  Future<void> _showNextLevelUpDialog() async {
    if (_isShowingLevelUpDialog) return;
    final batchResults = PlayerProgressionService.consumePendingLevelUps();
    if (batchResults.isEmpty) return;

    _isShowingLevelUpDialog = true;
    try {
      final xpTotal = await StorageService.getPlayerXpTotal();
      if (!mounted) return;
      final batch = LevelUpBatch.fromResults(batchResults, xpTotal);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => LevelUpDialog(palette: _palette, batch: batch),
      );
    } finally {
      _isShowingLevelUpDialog = false;
      if (mounted &&
          PlayerProgressionService.pendingLevelUps.value.isNotEmpty &&
          PlayerProgressionService.dialogSafe.value) {
        _onProgressionChanged();
      } else if (mounted && _pendingRewardDialog) {
        // Stage 4 fix: reward که به تعویق افتاده بود را الان نمایش بده
        _pendingRewardDialog = false;
        _showRewardDialog();
      }
    }
  }
}
