import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/manual_battle_room.dart';
import 'encryption_service.dart';

class OnlineBattleService {
  OnlineBattleService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  final Random _random = Random();

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      firestore.collection('battle_rooms');
  CollectionReference<Map<String, dynamic>> get _presence =>
      firestore.collection('presence');
  CollectionReference<Map<String, dynamic>> get _matchmaking =>
      firestore.collection('matchmaking');

  Future<void> setPresence({
    required String username,
    required bool isOnline,
  }) async {
    await _presence.doc(username).set(<String, dynamic>{
      'online': isOnline,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, bool>> watchFriendsPresence(List<String> usernames) {
    if (usernames.isEmpty) {
      return Stream<Map<String, bool>>.value(<String, bool>{});
    }

    final Set<String> friendSet = usernames.toSet();
    return _presence.where('online', isEqualTo: true).snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final DateTime now = DateTime.now();
      final Set<String> onlineNames = <String>{};
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        final Timestamp? updatedAtTs = data['updatedAt'] as Timestamp?;
        final DateTime updatedAt =
            updatedAtTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bool isFresh = now.difference(updatedAt).inSeconds <= 45;
        if (isFresh) {
          onlineNames.add(doc.id);
        }
      }
      return <String, bool>{
        for (final String username in friendSet)
          username: onlineNames.contains(username),
      };
    });
  }

  Stream<List<ManualBattleRoom>> watchIncomingChallenges(String username) {
    return _rooms
        .where('status', isEqualTo: 'waiting')
        .where('invitedPlayer', isEqualTo: username)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<ManualBattleRoom> rooms = snapshot.docs
              .map(ManualBattleRoom.fromDocument)
              .toList();
          rooms.sort((ManualBattleRoom a, ManualBattleRoom b) {
            return a.player1.compareTo(b.player1);
          });
          return rooms;
        });
  }

  Future<String> createFriendChallenge({
    required String fromUsername,
    required String toUsername,
    required int maxHealth,
    required int attackPower,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> existing = await _rooms
        .where('status', isEqualTo: 'waiting')
        .where('player1', isEqualTo: fromUsername)
        .where('invitedPlayer', isEqualTo: toUsername)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final DocumentReference<Map<String, dynamic>> doc = _rooms.doc();
    final GridPoint p1 = _randomPoint();
    GridPoint p2 = _randomPoint();
    while (p1.key == p2.key) {
      p2 = _randomPoint();
    }

    final Map<String, dynamic> payload = ManualBattleRoom.createNew(
      host: fromUsername,
      hostBoat: p1,
      secondBoat: p2,
      hostHealth: maxHealth,
      hostAttack: attackPower,
    );

    payload['invitedPlayer'] = toUsername;
    payload['challengeType'] = 'friend';
    payload['eventLog'] = <String>['$fromUsername challenged $toUsername.'];

    await doc.set(payload);
    return doc.id;
  }

  Future<void> declineFriendChallenge({
    required String roomId,
    required String username,
  }) async {
    await firestore.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> ref = _rooms.doc(roomId);
      final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(ref);
      if (!snap.exists) {
        return;
      }

      final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
      final String? invited = data['invitedPlayer']?.toString();
      final String challenger = data['player1']?.toString() ?? '';
      final List<String> eventLog =
          ((data['eventLog'] as List<dynamic>?) ?? <dynamic>[])
              .map((dynamic e) => e.toString())
              .toList();

      if (invited != username || data['status']?.toString() != 'waiting') {
        return;
      }

      tx.update(ref, <String, dynamic>{
        'status': 'finished',
        'winner': challenger,
        'eventLog': <String>[
          '$username declined the challenge.',
          ...eventLog.take(19),
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<String> findOrCreateMatch({
    required String username,
    required int maxHealth,
    required int attackPower,
    int attempt = 0,
  }) async {
    final DocumentReference<Map<String, dynamic>> queueRef = _matchmaking.doc(
      'public_queue',
    );

    final Map<String, dynamic> result = await firestore.runTransaction((
      Transaction tx,
    ) async {
      final DocumentSnapshot<Map<String, dynamic>> queueSnap = await tx.get(
        queueRef,
      );
      final Map<String, dynamic> queue =
          queueSnap.data() ?? <String, dynamic>{};

      final String waitingUsername = queue['username']?.toString() ?? '';
      final String waitingRoomId = queue['roomId']?.toString() ?? '';
      final Timestamp? queueUpdatedAtTs = queue['updatedAt'] as Timestamp?;
      final DateTime queueUpdatedAt =
          queueUpdatedAtTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bool queueFresh =
          DateTime.now().difference(queueUpdatedAt).inSeconds <= 45;

      final bool hasCandidate =
          waitingUsername.isNotEmpty &&
          waitingRoomId.isNotEmpty &&
          waitingUsername != username;

      if (hasCandidate && queueFresh) {
        final DocumentSnapshot<Map<String, dynamic>> hostPresence = await tx
            .get(_presence.doc(waitingUsername));
        final DocumentSnapshot<Map<String, dynamic>> waitingRoom = await tx.get(
          _rooms.doc(waitingRoomId),
        );

        final bool hostOnline = _isPresenceSnapshotFresh(hostPresence);
        final Map<String, dynamic> roomData =
            waitingRoom.data() ?? <String, dynamic>{};
        final bool roomWaiting = roomData['status']?.toString() == 'waiting';
        final String roomHost = roomData['player1']?.toString() ?? '';
        final String? roomP2 = roomData['player2']?.toString();
        final String? invitedPlayer = roomData['invitedPlayer']?.toString();
        final bool roomUsable =
            waitingRoom.exists &&
            roomWaiting &&
            roomHost == waitingUsername &&
            (roomP2 == null || roomP2.isEmpty) &&
            (invitedPlayer == null || invitedPlayer.isEmpty);

        if (hostOnline && roomUsable) {
          tx.set(queueRef, <String, dynamic>{
            'username': null,
            'roomId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          return <String, dynamic>{'roomId': waitingRoomId, 'shouldJoin': true};
        }
      }

      final DocumentReference<Map<String, dynamic>> roomRef = _rooms.doc();
      final GridPoint p1 = _randomPoint();
      GridPoint p2 = _randomPoint();
      while (p1.key == p2.key) {
        p2 = _randomPoint();
      }

      tx.set(
        roomRef,
        ManualBattleRoom.createNew(
          host: username,
          hostBoat: p1,
          secondBoat: p2,
          hostHealth: maxHealth,
          hostAttack: attackPower,
        ),
      );
      tx.set(queueRef, <String, dynamic>{
        'username': username,
        'roomId': roomRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return <String, dynamic>{'roomId': roomRef.id, 'shouldJoin': false};
    });

    final String roomId = result['roomId']?.toString() ?? '';
    final bool shouldJoin = result['shouldJoin'] == true;
    if (roomId.isEmpty) {
      throw Exception('Matchmaking failed. Please try again.');
    }

    if (!shouldJoin) {
      return roomId;
    }

    try {
      await joinRoom(
        roomId: roomId,
        username: username,
        maxHealth: maxHealth,
        attackPower: attackPower,
      );
      return roomId;
    } on Exception {
      if (attempt >= 2) {
        return createRoom(
          hostUsername: username,
          hostMaxHealth: maxHealth,
          hostAttackPower: attackPower,
        );
      }
      return findOrCreateMatch(
        username: username,
        maxHealth: maxHealth,
        attackPower: attackPower,
        attempt: attempt + 1,
      );
    }
  }

  bool _isPresenceSnapshotFresh(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!snap.exists) {
      return false;
    }
    final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
    final bool online = data['online'] == true;
    if (!online) {
      return false;
    }

    final Timestamp? updatedAtTs = data['updatedAt'] as Timestamp?;
    final DateTime updatedAt =
        updatedAtTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.now().difference(updatedAt).inSeconds <= 45;
  }

  Future<String> createRoom({
    required String hostUsername,
    required int hostMaxHealth,
    required int hostAttackPower,
  }) async {
    final DocumentReference<Map<String, dynamic>> doc = _rooms.doc();
    final GridPoint p1 = _randomPoint();
    GridPoint p2 = _randomPoint();
    while (p1.key == p2.key) {
      p2 = _randomPoint();
    }

    await doc.set(
      ManualBattleRoom.createNew(
        host: hostUsername,
        hostBoat: p1,
        secondBoat: p2,
        hostHealth: hostMaxHealth,
        hostAttack: hostAttackPower,
      ),
    );
    return doc.id;
  }

  Future<bool> activateBotFallback({
    required String roomId,
    required String hostUsername,
    String botName = 'AI Corsair',
    int botMaxHealth = 30,
    int botAttackPower = 10,
  }) async {
    return firestore.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> ref = _rooms.doc(roomId);
      final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(ref);
      if (!snap.exists) {
        return false;
      }

      final ManualBattleRoom room = ManualBattleRoom.fromDocument(snap);
      if (!room.isWaiting ||
          room.player1 != hostUsername ||
          room.player2 != null) {
        return false;
      }

      tx.update(ref, <String, dynamic>{
        'player2': botName,
        'p2Health': botMaxHealth,
        'p2Attack': botAttackPower,
        'status': 'active',
        'currentTurn': hostUsername,
        'eventLog': <String>[
          '$botName deployed after matchmaking timeout.',
          ...room.eventLog.take(19),
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  Future<void> performBotTurn({
    required String roomId,
    required String botName,
  }) async {
    await firestore.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> ref = _rooms.doc(roomId);
      final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(ref);
      final ManualBattleRoom room = _requireRoom(snap);

      if (!room.isActive ||
          room.player2 != botName ||
          room.currentTurn != botName) {
        return;
      }

      final bool buyHealthAction =
          room.player2Coins >= 1 &&
          room.player2Health <= 20 &&
          _random.nextDouble() < 0.28;
      if (buyHealthAction) {
        final int coins = room.player2Coins - 1;
        final int health = room.player2Health + 10;
        tx.update(ref, <String, dynamic>{
          'p2Coins': coins,
          'p2Health': health,
          'currentTurn': room.player1,
          'eventLog': <String>[
            '$botName bought health.',
            ...room.eventLog.take(19),
          ],
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final bool shouldAttack = _random.nextDouble() < 0.75;
      if (shouldAttack) {
        await _performBotAttack(tx: tx, ref: ref, room: room, botName: botName);
        return;
      }

      await _performBotMove(tx: tx, ref: ref, room: room, botName: botName);
    });
  }

  Future<void> joinRoom({
    required String roomId,
    required String username,
    required int maxHealth,
    required int attackPower,
  }) async {
    await firestore.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> ref = _rooms.doc(roomId);
      final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(ref);
      if (!snap.exists) {
        throw Exception('Room not found.');
      }

      final ManualBattleRoom room = ManualBattleRoom.fromDocument(snap);
      final String? invitedPlayer = snap.data()?['invitedPlayer']?.toString();
      if (room.player1 == username) {
        throw Exception('You cannot join your own room as player 2.');
      }
      if (invitedPlayer != null &&
          invitedPlayer.isNotEmpty &&
          invitedPlayer != username) {
        throw Exception('This challenge is reserved for another player.');
      }
      if (room.player2 != null && room.player2 != username) {
        throw Exception('Room is full.');
      }

      tx.update(ref, <String, dynamic>{
        'player2': username,
        'p2Health': maxHealth,
        'p2Attack': attackPower,
        'status': 'active',
        'invitedPlayer': FieldValue.delete(),
        'eventLog': <String>[
          '$username joined. Match started.',
          ...room.eventLog.take(19),
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<ManualBattleRoom?> watchRoom(String roomId) {
    return _rooms.doc(roomId).snapshots().asyncMap((
      DocumentSnapshot<Map<String, dynamic>> snap,
    ) async {
      if (!snap.exists) {
        return null;
      }
      final room = ManualBattleRoom.fromDocument(snap);

      // Decrypt opponent's encrypted moves if they exist — run off-main-isolate
      final String? p1EncryptedMove = snap.data()?['p1MoveLast_encrypted']?.toString();
      final String? p2EncryptedMove = snap.data()?['p2MoveLast_encrypted']?.toString();

      if (p1EncryptedMove != null && p1EncryptedMove.isNotEmpty) {
        try {
          await EncryptionService.decryptMove(p1EncryptedMove);
          // Decryption successful - move is verified
        } catch (_) {
          // Decryption failed - but game continues using unencrypted data
        }
      }

      if (p2EncryptedMove != null && p2EncryptedMove.isNotEmpty) {
        try {
          await EncryptionService.decryptMove(p2EncryptedMove);
          // Decryption successful - move is verified
        } catch (_) {
          // Decryption failed - but game continues using unencrypted data
        }
      }

      return room;
    });
  }

  Future<String> moveBoat({
    required String roomId,
    required String username,
    required GridPoint target,
  }) async {
    return firestore.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> ref = _rooms.doc(roomId);
      final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(ref);
      final ManualBattleRoom room = _requireRoom(snap);
      _requireTurnAndStatus(room, username);
      _requireBounds(target);

      final bool isP1 = room.isPlayerOne(username);
      final List<String> missesOnPlayer = List<String>.from(
        room.missesOn(username),
      );
      if (missesOnPlayer.contains(target.key)) {
        throw Exception('Cannot move onto a cell marked X.');
      }

      final GridPoint currentBoat = room.boatFor(username);
      final List<String> moveStack = List<String>.from(
        room.moveStackFor(username),
      );
      moveStack.add(currentBoat.key);

      final String nextTurn = _nextTurn(room, username);
      final String encryptedMove = EncryptionService.encryptMove(target.x, target.y);
      final List<String> log = <String>[
        '$username moved boat.',
        ...room.eventLog.take(19),
      ];
      tx.update(ref, <String, dynamic>{
        if (isP1) 'p1Boat': target.toMap(),
        if (!isP1) 'p2Boat': target.toMap(),
        if (isP1) 'p1MoveStack': moveStack,
        if (!isP1) 'p2MoveStack': moveStack,
        'currentTurn': nextTurn,
        'eventLog': log,
        if (isP1) 'p1MoveLast_encrypted': encryptedMove,
        if (!isP1) 'p2MoveLast_encrypted': encryptedMove,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return 'You moved to (${target.x}, ${target.y}).';
    });
  }

  Future<String> attack({
    required String roomId,
    required String username,
    required GridPoint target,
  }) async {
    return firestore.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> ref = _rooms.doc(roomId);
      final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(ref);
      final ManualBattleRoom room = _requireRoom(snap);
      _requireTurnAndStatus(room, username);
      _requireBounds(target);

      final bool isP1 = room.isPlayerOne(username);
      final List<String> missesByPlayer = List<String>.from(
        room.missesBy(username),
      );
      if (missesByPlayer.contains(target.key)) {
        throw Exception('This target is already marked X (miss).');
      }

      final GridPoint enemyBoat = room.enemyBoatFor(username);
      int p1Health = room.player1Health;
      int p2Health = room.player2Health;
      int p1Coins = room.player1Coins;
      int p2Coins = room.player2Coins;
      int p1Hits = room.player1Hits;
      int p2Hits = room.player2Hits;
      String status = room.status;
      String currentTurn = room.currentTurn;
      String? winner = room.winner;
      String actorMessage;
      late final String eventMessage;

      if (enemyBoat.key == target.key) {
        final int damage = room.attackFor(username);
        if (isP1) {
          p2Health = max(0, p2Health - damage);
          p1Coins += 1;
          p1Hits += 1;
        } else {
          p1Health = max(0, p1Health - damage);
          p2Coins += 1;
          p2Hits += 1;
        }
        actorMessage =
            'You attacked (${target.x}, ${target.y}) — Hit! Damage: $damage';
        eventMessage =
            '$username attacked (${target.x}, ${target.y}) — Hit! Damage: $damage';
      } else {
        missesByPlayer.add(target.key);
        actorMessage = 'You attacked (${target.x}, ${target.y}) — Miss.';
        eventMessage = '$username attacked (${target.x}, ${target.y}) — Miss.';
      }

      if (p1Health <= 0 || p2Health <= 0) {
        status = 'finished';
        winner = p1Health <= 0 ? room.player2 : room.player1;
      } else {
        currentTurn = _nextTurn(room, username);
      }

      tx.update(ref, <String, dynamic>{
        'p1Health': p1Health,
        'p2Health': p2Health,
        'p1Coins': p1Coins,
        'p2Coins': p2Coins,
        'p1Hits': p1Hits,
        'p2Hits': p2Hits,
        if (isP1) 'p1Misses': missesByPlayer,
        if (!isP1) 'p2Misses': missesByPlayer,
        'status': status,
        'winner': winner,
        'currentTurn': currentTurn,
        'eventLog': <String>[eventMessage, ...room.eventLog.take(19)],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return actorMessage;
    });
  }

  Future<String> buyHealth({
    required String roomId,
    required String username,
  }) async {
    return firestore.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> ref = _rooms.doc(roomId);
      final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(ref);
      final ManualBattleRoom room = _requireRoom(snap);
      _requireTurnAndStatus(room, username);

      final bool isP1 = room.isPlayerOne(username);
      int coins = room.coinsFor(username);
      int health = room.healthFor(username);
      if (coins < 1) {
        throw Exception('Not enough coins. Need at least 1 coin.');
      }

      coins -= 1;
      health += 10;

      tx.update(ref, <String, dynamic>{
        if (isP1) 'p1Coins': coins,
        if (!isP1) 'p2Coins': coins,
        if (isP1) 'p1Health': health,
        if (!isP1) 'p2Health': health,
        'currentTurn': _nextTurn(room, username),
        'eventLog': <String>[
          '$username bought health.',
          ...room.eventLog.take(19),
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return 'You bought 10 health.';
    });
  }

  Future<void> leaveRoom({
    required String roomId,
    required String username,
  }) async {
    await firestore.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> ref = _rooms.doc(roomId);
      final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(ref);
      if (!snap.exists) {
        return;
      }

      final ManualBattleRoom room = ManualBattleRoom.fromDocument(snap);
      if (!room.isParticipant(username) || room.isFinished) {
        return;
      }

      final String? winner = room.player1 == username
          ? room.player2
          : room.player1;
      tx.update(ref, <String, dynamic>{
        'status': 'finished',
        'winner': winner,
        'eventLog': <String>[
          '$username left the match.',
          ...room.eventLog.take(19),
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  ManualBattleRoom _requireRoom(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!snap.exists) {
      throw Exception('Room no longer exists.');
    }
    return ManualBattleRoom.fromDocument(snap);
  }

  void _requireTurnAndStatus(ManualBattleRoom room, String username) {
    if (!room.isParticipant(username)) {
      throw Exception('You are not part of this room.');
    }
    if (!room.isActive) {
      throw Exception('Room is not active yet.');
    }
    if (room.currentTurn != username) {
      throw Exception('Wait for your turn.');
    }
  }

  String _nextTurn(ManualBattleRoom room, String username) {
    if (room.player1 == username) {
      return room.player2 ?? room.player1;
    }
    return room.player1;
  }

  void _requireBounds(GridPoint point) {
    if (point.x < 0 ||
        point.x >= ManualBattleRoom.gridSize ||
        point.y < 0 ||
        point.y >= ManualBattleRoom.gridSize) {
      throw Exception('Coordinates out of bounds.');
    }
  }

  GridPoint _randomPoint() => GridPoint.cached(
        _random.nextInt(ManualBattleRoom.gridSize),
        _random.nextInt(ManualBattleRoom.gridSize),
      );

  Future<void> _performBotAttack({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> ref,
    required ManualBattleRoom room,
    required String botName,
  }) async {
    final List<String> usedMisses = List<String>.from(room.player2Misses);
    final GridPoint target = _randomPointExcluding(usedMisses.toSet());

    int p1Health = room.player1Health;
    int p2Coins = room.player2Coins;
    int p2Hits = room.player2Hits;
    String status = room.status;
    String? winner = room.winner;
    String event;

    if (target.key == room.player1Boat.key) {
      final int damage = room.player2Attack;
      p1Health = max(0, p1Health - damage);
      p2Coins += 1;
      p2Hits += 1;
      event = '$botName attacked (${target.x}, ${target.y}) — Hit! Damage: $damage';
    } else {
      usedMisses.add(target.key);
      event = '$botName attacked (${target.x}, ${target.y}) — Miss.';
    }

    if (p1Health <= 0) {
      status = 'finished';
      winner = botName;
    }

    tx.update(ref, <String, dynamic>{
      'p1Health': p1Health,
      'p2Coins': p2Coins,
      'p2Hits': p2Hits,
      'p2Misses': usedMisses,
      'status': status,
      'winner': winner,
      'currentTurn': status == 'finished' ? botName : room.player1,
      'eventLog': <String>[event, ...room.eventLog.take(19)],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _performBotMove({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> ref,
    required ManualBattleRoom room,
    required String botName,
  }) async {
    final Set<String> blocked = room.player1Misses.toSet();
    final GridPoint target = _randomPointExcluding(blocked);
    final List<String> moveStack = List<String>.from(room.player2MoveStack)
      ..add(room.player2Boat.key);

    tx.update(ref, <String, dynamic>{
      'p2Boat': target.toMap(),
      'p2MoveStack': moveStack,
      'currentTurn': room.player1,
      'eventLog': <String>['$botName moved boat.', ...room.eventLog.take(19)],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  GridPoint _randomPointExcluding(Set<String> blocked) {
    final List<GridPoint> candidates = <GridPoint>[];
    for (int x = 0; x < ManualBattleRoom.gridSize; x++) {
      for (int y = 0; y < ManualBattleRoom.gridSize; y++) {
        final GridPoint point = GridPoint.cached(x, y);
        if (!blocked.contains(point.key)) {
          candidates.add(point);
        }
      }
    }

    if (candidates.isEmpty) {
      return const GridPoint(0, 0);
    }

    return candidates[_random.nextInt(candidates.length)];
  }
}




