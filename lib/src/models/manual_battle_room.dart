import 'package:cloud_firestore/cloud_firestore.dart';

class GridPoint {
  const GridPoint(this.x, this.y);

  final int x;
  final int y;

  // Cached GridPoint instances to avoid repeated allocations for the fixed grid size.
  static late final List<List<GridPoint>> _cache = List<List<GridPoint>>.generate(
    ManualBattleRoom.gridSize,
    (int x) => List<GridPoint>.generate(
      ManualBattleRoom.gridSize,
      (int y) => GridPoint(x, y),
      growable: false,
    ),
    growable: false,
  );

  /// Return a cached GridPoint for the grid coordinates.
  static GridPoint cached(int x, int y) {
    final int max = ManualBattleRoom.gridSize - 1;
    final int xx = (x < 0) ? 0 : (x > max ? max : x);
    final int yy = (y < 0) ? 0 : (y > max ? max : y);
    return _cache[xx][yy];
  }

  String get key => '${x}_$y';

  static GridPoint fromKey(String key) {
    final List<String> parts = key.split('_');
    if (parts.length != 2) {
      return GridPoint.cached(0, 0);
    }
    return GridPoint.cached(int.parse(parts[0]), int.parse(parts[1]));
  }

  Map<String, int> toMap() => <String, int>{'x': x, 'y': y};

  factory GridPoint.fromMap(Map<String, dynamic> map) {
    return GridPoint.cached(
      (map['x'] as num?)?.toInt() ?? 0,
      (map['y'] as num?)?.toInt() ?? 0,
    );
  }
}

class ManualBattleRoom {
  static const int gridSize = 6;

  const ManualBattleRoom({
    required this.id,
    required this.status,
    required this.player1,
    required this.player2,
    required this.currentTurn,
    required this.player1Health,
    required this.player2Health,
    required this.player1Coins,
    required this.player2Coins,
    required this.player1Hits,
    required this.player2Hits,
    required this.player1Attack,
    required this.player2Attack,
    required this.player1Boat,
    required this.player2Boat,
    required this.player1Misses,
    required this.player2Misses,
    required this.player1MoveStack,
    required this.player2MoveStack,
    required this.eventLog,
    this.winner,
  });

  final String id;
  final String status;
  final String player1;
  final String? player2;
  final String currentTurn;
  final int player1Health;
  final int player2Health;
  final int player1Coins;
  final int player2Coins;
  final int player1Hits;
  final int player2Hits;
  final int player1Attack;
  final int player2Attack;
  final GridPoint player1Boat;
  final GridPoint player2Boat;
  final List<String> player1Misses;
  final List<String> player2Misses;
  final List<String> player1MoveStack;
  final List<String> player2MoveStack;
  final List<String> eventLog;
  final String? winner;

  bool get isWaiting => status == 'waiting';
  bool get isActive => status == 'active';
  bool get isFinished => status == 'finished';
  bool get isBotMatch => (player2 ?? '').startsWith('AI ');
  String? get botName => isBotMatch ? player2 : null;

  bool isParticipant(String username) =>
      player1 == username || player2 == username;
  bool isPlayerOne(String username) => player1 == username;

  int healthFor(String username) =>
      isPlayerOne(username) ? player1Health : player2Health;
  int coinsFor(String username) =>
      isPlayerOne(username) ? player1Coins : player2Coins;
  int hitsFor(String username) =>
      isPlayerOne(username) ? player1Hits : player2Hits;
    int attackFor(String username) =>
      isPlayerOne(username) ? player1Attack : player2Attack;
  GridPoint boatFor(String username) =>
      isPlayerOne(username) ? player1Boat : player2Boat;
  GridPoint enemyBoatFor(String username) =>
      isPlayerOne(username) ? player2Boat : player1Boat;

  List<String> missesBy(String username) =>
      isPlayerOne(username) ? player1Misses : player2Misses;
  List<String> missesOn(String username) =>
      isPlayerOne(username) ? player2Misses : player1Misses;

  List<String> moveStackFor(String username) =>
      isPlayerOne(username) ? player1MoveStack : player2MoveStack;

  static ManualBattleRoom fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return ManualBattleRoom(
      id: doc.id,
      status: data['status']?.toString() ?? 'waiting',
      player1: data['player1']?.toString() ?? '',
      player2: data['player2']?.toString(),
      currentTurn: data['currentTurn']?.toString() ?? '',
      player1Health: (data['p1Health'] as num?)?.toInt() ?? 30,
      player2Health: (data['p2Health'] as num?)?.toInt() ?? 30,
      player1Coins: (data['p1Coins'] as num?)?.toInt() ?? 0,
      player2Coins: (data['p2Coins'] as num?)?.toInt() ?? 0,
      player1Hits: (data['p1Hits'] as num?)?.toInt() ?? 0,
      player2Hits: (data['p2Hits'] as num?)?.toInt() ?? 0,
      player1Attack: (data['p1Attack'] as num?)?.toInt() ?? 10,
      player2Attack: (data['p2Attack'] as num?)?.toInt() ?? 10,
      player1Boat: _sanitizePoint(
        GridPoint.fromMap(
          (data['p1Boat'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        ),
      ),
      player2Boat: _sanitizePoint(
        GridPoint.fromMap(
          (data['p2Boat'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        ),
      ),
      player1Misses: ((data['p1Misses'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic v) => v.toString())
          .toList(),
      player2Misses: ((data['p2Misses'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic v) => v.toString())
          .toList(),
      player1MoveStack: ((data['p1MoveStack'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic v) => v.toString())
          .toList(),
      player2MoveStack: ((data['p2MoveStack'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic v) => v.toString())
          .toList(),
      eventLog: ((data['eventLog'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic v) => v.toString())
          .toList(),
      winner: data['winner']?.toString(),
    );
  }

  static Map<String, dynamic> createNew({
    required String host,
    required GridPoint hostBoat,
    required GridPoint secondBoat,
    int hostHealth = 30,
    int secondHealth = 30,
    int hostAttack = 10,
    int secondAttack = 10,
  }) {
    return <String, dynamic>{
      'status': 'waiting',
      'player1': host,
      'player2': null,
      'currentTurn': host,
      'p1Health': hostHealth,
      'p2Health': secondHealth,
      'p1Coins': 0,
      'p2Coins': 0,
      'p1Hits': 0,
      'p2Hits': 0,
      'p1Attack': hostAttack,
      'p2Attack': secondAttack,
      'p1Boat': hostBoat.toMap(),
      'p2Boat': secondBoat.toMap(),
      'p1Misses': <String>[],
      'p2Misses': <String>[],
      'p1MoveStack': <String>[],
      'p2MoveStack': <String>[],
      'eventLog': <String>['Room created by $host. Waiting for challenger...'],
      'winner': null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static GridPoint _sanitizePoint(GridPoint point) {
    final int max = gridSize - 1;
    final int x = point.x.clamp(0, max) as int;
    final int y = point.y.clamp(0, max) as int;
    return GridPoint.cached(x, y);
  }
}
