enum PowerUpType { golden, shield, slow, ghost }
class PowerUp {
  final PowerUpType type;
  const PowerUp(this.type);

  static const golden = PowerUp(PowerUpType.golden);
  static const shield = PowerUp(PowerUpType.shield);
  static const slow = PowerUp(PowerUpType.slow);
  static const ghost = PowerUp(PowerUpType.ghost);}