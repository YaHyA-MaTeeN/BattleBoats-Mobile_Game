class BattleState {
  BattleState({
    required this.playerName,
    required this.enemyName,
    required this.playerPosition,
    required this.enemyPosition,
    required this.playerHealth,
    required this.enemyHealth,
    required this.eventLog,
    required this.isFinished,
    this.winner,
  });

  final String playerName;
  final String enemyName;
  final double playerPosition;
  final double enemyPosition;
  final int playerHealth;
  final int enemyHealth;
  final List<String> eventLog;
  final bool isFinished;
  final String? winner;

  BattleState copyWith({
    double? playerPosition,
    double? enemyPosition,
    int? playerHealth,
    int? enemyHealth,
    List<String>? eventLog,
    bool? isFinished,
    String? winner,
  }) {
    return BattleState(
      playerName: playerName,
      enemyName: enemyName,
      playerPosition: playerPosition ?? this.playerPosition,
      enemyPosition: enemyPosition ?? this.enemyPosition,
      playerHealth: playerHealth ?? this.playerHealth,
      enemyHealth: enemyHealth ?? this.enemyHealth,
      eventLog: eventLog ?? List<String>.from(this.eventLog),
      isFinished: isFinished ?? this.isFinished,
      winner: winner ?? this.winner,
    );
  }
}
