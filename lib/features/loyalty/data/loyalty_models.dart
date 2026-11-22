class LoyaltyReward {
  const LoyaltyReward({
    required this.id,
    required this.name,
    required this.points,
    required this.discountValue,
    required this.minOrderAmount,
  });

  final String id;
  final String name;
  final int points;
  final double discountValue;
  final double minOrderAmount;

  factory LoyaltyReward.fromJson(Map<String, dynamic> json) {
    return LoyaltyReward(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      points: _int(json['points']),
      discountValue: _double(json['discountValue']),
      minOrderAmount: _double(json['minOrderAmount']),
    );
  }
}

class LoyaltyEntry {
  const LoyaltyEntry({
    required this.id,
    required this.delta,
    required this.type,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final int delta;
  final String type;
  final String reason;
  final DateTime? createdAt;

  factory LoyaltyEntry.fromJson(Map<String, dynamic> json) {
    return LoyaltyEntry(
      id: json['id'].toString(),
      delta: _int(json['delta']),
      type: (json['type'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString())
          ?.toLocal(),
    );
  }
}

class LoyaltySummary {
  const LoyaltySummary({
    required this.points,
    required this.lifetimePoints,
    required this.tier,
    required this.tierLabel,
    required this.nextTierLabel,
    required this.pointsToNextTier,
    required this.rewards,
    required this.history,
  });

  final int points;
  final int lifetimePoints;
  final String tier;
  final String tierLabel;
  final String? nextTierLabel;
  final int pointsToNextTier;
  final List<LoyaltyReward> rewards;
  final List<LoyaltyEntry> history;

  /// Tiến độ lên hạng kế tiếp trong khoảng 0..1.
  double get progress {
    if (nextTierLabel == null) {
      return 1;
    }
    final total = lifetimePoints + pointsToNextTier;
    return total <= 0 ? 0 : (lifetimePoints / total).clamp(0, 1).toDouble();
  }

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) {
    final rewards = json['rewards'];
    final history = json['history'];
    Map<String, dynamic> asMap(Object? v) => v is Map
        ? v.map((k, x) => MapEntry(k.toString(), x))
        : <String, dynamic>{};
    return LoyaltySummary(
      points: _int(json['points']),
      lifetimePoints: _int(json['lifetimePoints']),
      tier: (json['tier'] ?? 'BRONZE').toString(),
      tierLabel: (json['tierLabel'] ?? 'Đồng').toString(),
      nextTierLabel: json['nextTierLabel']?.toString(),
      pointsToNextTier: _int(json['pointsToNextTier']),
      rewards: rewards is List
          ? rewards.map((e) => LoyaltyReward.fromJson(asMap(e))).toList()
          : const [],
      history: history is List
          ? history.map((e) => LoyaltyEntry.fromJson(asMap(e))).toList()
          : const [],
    );
  }
}

int _int(Object? value) => (num.tryParse(value?.toString() ?? '') ?? 0).round();
double _double(Object? value) =>
    (num.tryParse(value?.toString() ?? '') ?? 0).toDouble();
