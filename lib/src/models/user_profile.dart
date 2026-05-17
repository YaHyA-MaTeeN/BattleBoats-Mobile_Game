class UserProfile {
  UserProfile({
    required this.username,
    required this.coins,
    required this.hullLevel,
    required this.cannonLevel,
    required this.friends,
  });

  final String username;
  final int coins;
  final int hullLevel;
  final int cannonLevel;
  final List<String> friends;

  int get maxHealth => 30 + (hullLevel - 1) * 10;
  int get attackPower => 16 + (cannonLevel - 1) * 6;

  int get hullUpgradeCost => hullLevel * 90;
  int get cannonUpgradeCost => cannonLevel * 100;

  UserProfile copyWith({
    int? coins,
    int? hullLevel,
    int? cannonLevel,
    List<String>? friends,
  }) {
    return UserProfile(
      username: username,
      coins: coins ?? this.coins,
      hullLevel: hullLevel ?? this.hullLevel,
      cannonLevel: cannonLevel ?? this.cannonLevel,
      friends: friends ?? List<String>.from(this.friends),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'username': username,
      'coins': coins,
      'hullLevel': hullLevel,
      'cannonLevel': cannonLevel,
      'friends': friends,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] as String,
      coins: (json['coins'] as num?)?.toInt() ?? 300,
      hullLevel: (json['hullLevel'] as num?)?.toInt() ?? 1,
      cannonLevel: (json['cannonLevel'] as num?)?.toInt() ?? 1,
      friends: ((json['friends'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
    );
  }
}
