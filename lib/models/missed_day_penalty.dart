/// What one rollover charged for missed days, for the QUEST FAILED window.
class MissedDayPenalty {
  final int days;
  final int xpLost;
  final int fromLevel;
  final int toLevel;

  /// Misses left before a level can be lost; 0 once protection is gone.
  final int protectionLeft;

  const MissedDayPenalty({
    required this.days,
    required this.xpLost,
    required this.fromLevel,
    required this.toLevel,
    required this.protectionLeft,
  });

  bool get lostLevel => toLevel < fromLevel;

  @override
  bool operator ==(Object other) =>
      other is MissedDayPenalty &&
      other.days == days &&
      other.xpLost == xpLost &&
      other.fromLevel == fromLevel &&
      other.toLevel == toLevel &&
      other.protectionLeft == protectionLeft;

  @override
  int get hashCode =>
      Object.hash(days, xpLost, fromLevel, toLevel, protectionLeft);

  @override
  String toString() =>
      'MissedDayPenalty(days: $days, xpLost: $xpLost, '
      'Lv $fromLevel -> $toLevel, protectionLeft: $protectionLeft)';
}
