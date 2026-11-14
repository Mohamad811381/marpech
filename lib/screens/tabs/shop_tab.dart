import 'package:flutter/material.dart';
import '../../models/game_palette.dart';
import '../shop_screen.dart';

class ShopTab extends StatelessWidget {
  final GamePalette palette;
  final VoidCallback? onPaletteChanged;

  const ShopTab({
    super.key,
    required this.palette,
    this.onPaletteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ShopScreen(
      palette: palette,
      embedded: true,
      onPaletteChanged: onPaletteChanged,
    );
  }
}
