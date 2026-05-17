import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/manual_battle_room.dart';
import '../models/user_profile.dart';
import '../services/firebase_bootstrap.dart';
import '../services/local_backend_service.dart';
import '../services/notification_service.dart';
import '../services/online_battle_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    required LocalBackendService backend,
    required OnlineBattleService onlineService,
  }) : _backend = backend,
       _onlineService = onlineService;

  final LocalBackendService _backend;
  final OnlineBattleService _onlineService;
  final NotificationService _notificationService = NotificationService();

  UserProfile? _currentUser;
  List<String> _incomingRequests = <String>[];
  Map<String, bool> _friendOnlineStatus = <String, bool>{};
  List<ManualBattleRoom> _incomingChallenges = <ManualBattleRoom>[];
  ManualBattleRoom? _activeRoom;
  StreamSubscription<ManualBattleRoom?>? _roomSubscription;
  StreamSubscription<Map<String, bool>>? _presenceSubscription;
  StreamSubscription<List<ManualBattleRoom>>? _challengeSubscription;
  Timer? _presenceHeartbeatTimer;
  Timer? _botFallbackTimer;
  Timer? _botTurnTimer;
  final Set<String> _rewardedRoomIds = <String>{};
  String? _flashMessage;
  String? _lastRoomEvent;
  bool _isBusy = false;
  String? _error;

  UserProfile? get currentUser => _currentUser;
  List<String> get incomingRequests =>
      List<String>.unmodifiable(_incomingRequests);
  List<ManualBattleRoom> get incomingChallenges =>
      List<ManualBattleRoom>.unmodifiable(_incomingChallenges);
  ManualBattleRoom? get activeRoom => _activeRoom;
  bool isFriendOnline(String username) =>
      _friendOnlineStatus[username] ?? false;
  bool get isInRoom => _activeRoom != null;
  bool get isBusy => _isBusy;
  String? get error => _error;
  String? get flashMessage => _flashMessage;
  bool get isLoggedIn => _currentUser != null;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void consumeFlashMessage() {
    _flashMessage = null;
  }

  Future<bool> signUp(String username, String email, String password) async {
    return _runAuth(
      () =>
          _backend.signUp(username: username, email: email, password: password),
    );
  }

  Future<bool> login(String username, String password) async {
    return _runAuth(
      () => _backend.login(username: username, password: password),
    );
  }

  Future<bool> resetPassword({
    required String username,
    required String email,
  }) async {
    _setBusy(true);
    _error = null;
    try {
      await _backend.resetPassword(
        username: username,
        email: email,
      );
      return true;
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> _runAuth(Future<UserProfile> Function() fn) async {
    _setBusy(true);
    _error = null;
    try {
      _currentUser = await fn();
      _incomingRequests = await _backend.getIncomingRequests(
        _currentUser!.username,
      );
      await _notificationService.initialize();
      await _startRealtimeFriendFeatures();
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  void logout() {
    final String? username = _currentUser?.username;
    if (username != null && FirebaseBootstrap.isReady) {
      unawaited(
        _onlineService.setPresence(username: username, isOnline: false),
      );
    }

    _cancelBotTimers();
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
    _roomSubscription?.cancel();
    _roomSubscription = null;
    _presenceSubscription?.cancel();
    _presenceSubscription = null;
    _challengeSubscription?.cancel();
    _challengeSubscription = null;
    _currentUser = null;
    _incomingRequests = <String>[];
    _incomingChallenges = <ManualBattleRoom>[];
    _friendOnlineStatus = <String, bool>{};
    _activeRoom = null;
    _error = null;
    _flashMessage = null;
    _lastRoomEvent = null;
    notifyListeners();
  }

  Future<void> refreshRequests() async {
    if (_currentUser == null) return;
    _incomingRequests = await _backend.getIncomingRequests(
      _currentUser!.username,
    );
    notifyListeners();
  }

  Future<void> sendFriendRequest(String targetUsername) async {
    if (_currentUser == null) return;
    _setBusy(true);
    _error = null;
    try {
      await _backend.sendFriendRequest(
        fromUsername: _currentUser!.username,
        toUsername: targetUsername.trim(),
      );
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> acceptRequest(String requester) async {
    if (_currentUser == null) return;
    _setBusy(true);
    _error = null;
    try {
      _currentUser = await _backend.acceptFriendRequest(
        currentUser: _currentUser!.username,
        requester: requester,
      );
      _incomingRequests.remove(requester);
      _watchFriendPresence();
      await _notificationService.showFriendRequestAcceptedNotification(requester);
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> rejectRequest(String requester) async {
    if (_currentUser == null) return;
    _setBusy(true);
    _error = null;
    try {
      await _backend.rejectFriendRequest(
        currentUser: _currentUser!.username,
        requester: requester,
      );
      _incomingRequests.remove(requester);
      await _notificationService.showFriendRequestRejectedNotification(requester);
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<bool> challengeFriend(String friendUsername) async {
    if (_currentUser == null) return false;
    if (!FirebaseBootstrap.isReady) {
      _error =
          '${FirebaseBootstrap.error ?? 'Firebase is not initialized.'} Run `flutterfire configure` and add platform config files.';
      notifyListeners();
      return false;
    }

    _setBusy(true);
    _error = null;
    try {
      final String roomId = await _onlineService.createFriendChallenge(
        fromUsername: _currentUser!.username,
        toUsername: friendUsername,
        maxHealth: _currentUser!.maxHealth,
        attackPower: _currentUser!.attackPower,
      );
      _listenToRoom(roomId);
      return true;
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> acceptChallenge(String roomId) async {
    if (_currentUser == null) return false;
    _setBusy(true);
    _error = null;
    try {
      await _onlineService.joinRoom(
        roomId: roomId,
        username: _currentUser!.username,
        maxHealth: _currentUser!.maxHealth,
        attackPower: _currentUser!.attackPower,
      );
      _incomingChallenges.removeWhere(
        (ManualBattleRoom room) => room.id == roomId,
      );
      _listenToRoom(roomId);
      return true;
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> declineChallenge(String roomId) async {
    if (_currentUser == null) return;
    _setBusy(true);
    _error = null;
    try {
      String challengerName = 'Unknown';
      for (final ManualBattleRoom r in _incomingChallenges) {
        if (r.id == roomId) {
          challengerName = r.player1;
          break;
        }
      }
      
      await _onlineService.declineFriendChallenge(
        roomId: roomId,
        username: _currentUser!.username,
      );
      _incomingChallenges.removeWhere(
        (ManualBattleRoom room) => room.id == roomId,
      );
      await _notificationService.showBattleChallengeDeclinedNotification(challengerName);
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> upgradeHull() async {
    if (_currentUser == null) return;
    final UserProfile user = _currentUser!;
    if (user.coins < user.hullUpgradeCost) {
      _error = 'Not enough coins for hull upgrade.';
      notifyListeners();
      return;
    }

    final UserProfile updated = user.copyWith(
      coins: user.coins - user.hullUpgradeCost,
      hullLevel: user.hullLevel + 1,
    );
    await _persistProfile(updated);
  }

  Future<void> upgradeCannon() async {
    if (_currentUser == null) return;
    final UserProfile user = _currentUser!;
    if (user.coins < user.cannonUpgradeCost) {
      _error = 'Not enough coins for cannon upgrade.';
      notifyListeners();
      return;
    }

    final UserProfile updated = user.copyWith(
      coins: user.coins - user.cannonUpgradeCost,
      cannonLevel: user.cannonLevel + 1,
    );
    await _persistProfile(updated);
  }

  Future<void> _persistProfile(UserProfile updated) async {
    _error = null;
    _currentUser = updated;
    await _backend.updateProfile(updated);
    notifyListeners();
  }

  /// Grants coins to the current user and persists the profile.
  Future<void> grantCoins(int amount) async {
    if (_currentUser == null) return;
    final UserProfile updated = _currentUser!.copyWith(
      coins: _currentUser!.coins + amount,
    );
    await _persistProfile(updated);
  }

  Future<String?> createRoom() async {
    if (_currentUser == null) return null;
    _setBusy(true);
    _error = null;
    try {
      final String roomId = await _onlineService.createRoom(
        hostUsername: _currentUser!.username,
        hostMaxHealth: _currentUser!.maxHealth,
        hostAttackPower: _currentUser!.attackPower,
      );
      _listenToRoom(roomId);
      return roomId;
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> quickMatch() async {
    if (_currentUser == null) return false;
    if (!FirebaseBootstrap.isReady) {
      _error =
          '${FirebaseBootstrap.error ?? 'Firebase is not initialized.'} Run `flutterfire configure` and add platform config files.';
      notifyListeners();
      return false;
    }
    _setBusy(true);
    _error = null;
    try {
      final String roomId = await _onlineService.findOrCreateMatch(
        username: _currentUser!.username,
        maxHealth: _currentUser!.maxHealth,
        attackPower: _currentUser!.attackPower,
      );
      _listenToRoom(roomId);
      return true;
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> startBotMatchNow() async {
    if (_currentUser == null || _activeRoom == null) {
      return;
    }

    final ManualBattleRoom room = _activeRoom!;
    if (!room.isWaiting || room.player1 != _currentUser!.username) {
      _error = 'Only host can start AI fallback while waiting.';
      notifyListeners();
      return;
    }

    _setBusy(true);
    _error = null;
    try {
      final bool started = await _onlineService.activateBotFallback(
        roomId: room.id,
        hostUsername: _currentUser!.username,
        botName: 'AI Corsair',
        botMaxHealth: 30,
        botAttackPower: 10,
      );
      if (!started) {
        _error = 'Could not start AI fallback. Please try again.';
        notifyListeners();
      }
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> joinRoom(String roomId) async {
    if (_currentUser == null) return false;
    final String trimmed = roomId.trim();
    if (trimmed.isEmpty) {
      _error = 'Enter a room ID.';
      notifyListeners();
      return false;
    }

    _setBusy(true);
    _error = null;
    try {
      await _onlineService.joinRoom(
        roomId: trimmed,
        username: _currentUser!.username,
        maxHealth: _currentUser!.maxHealth,
        attackPower: _currentUser!.attackPower,
      );
      _listenToRoom(trimmed);
      return true;
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> leaveCurrentRoom() async {
    if (_currentUser == null || _activeRoom == null) return;
    try {
      await _onlineService.leaveRoom(
        roomId: _activeRoom!.id,
        username: _currentUser!.username,
      );
    } finally {
      _cancelBotTimers();
      await _roomSubscription?.cancel();
      _roomSubscription = null;
      _activeRoom = null;
      notifyListeners();
    }
  }

  Future<void> moveBoat(int x, int y) async {
      await _performRoomAction((String roomId, String username) {
        return _onlineService.moveBoat(
          roomId: roomId,
          username: username,
          target: GridPoint.cached(x, y),
        );
    });
  }

  Future<void> attack(int x, int y) async {
      await _performRoomAction((String roomId, String username) {
        return _onlineService.attack(
          roomId: roomId,
          username: username,
          target: GridPoint.cached(x, y),
        );
    });
  }

  Future<void> buyHealthInMatch() async {
    await _performRoomAction((String roomId, String username) {
      return _onlineService.buyHealth(roomId: roomId, username: username);
    });
  }

  Future<void> _performRoomAction(
    Future<String> Function(String roomId, String username) action,
  ) async {
    if (_currentUser == null || _activeRoom == null) return;
    _setBusy(true);
    _error = null;
    try {
      final String actorFeedback = await action(
        _activeRoom!.id,
        _currentUser!.username,
      );
      _flashMessage = actorFeedback;
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  void _listenToRoom(String roomId) {
    _cancelBotTimers();
    _roomSubscription?.cancel();
    _roomSubscription = _onlineService
        .watchRoom(roomId)
        .listen(
          (ManualBattleRoom? room) {
            if (room == null) {
              _cancelBotTimers();
              _activeRoom = null;
              notifyListeners();
              return;
            }

            _activeRoom = room;
            _scheduleBotFallbackIfNeeded(room);
            _scheduleBotTurnIfNeeded(room);
            _handleRoomEventPopup(room);
            _handleWinReward(room);
            notifyListeners();
          },
          onError: (Object e) {
            _error = e.toString();
            notifyListeners();
          },
        );
  }

  void _scheduleBotFallbackIfNeeded(ManualBattleRoom room) {
    final String? username = _currentUser?.username;
    if (username == null) {
      return;
    }

    final bool canStartFallback =
        room.isWaiting && room.player1 == username && room.player2 == null;

    if (!canStartFallback) {
      _botFallbackTimer?.cancel();
      _botFallbackTimer = null;
      return;
    }

    if (_botFallbackTimer != null && _botFallbackTimer!.isActive) {
      return;
    }

    _botFallbackTimer = Timer(const Duration(seconds: 20), () async {
      if (_currentUser == null) {
        return;
      }
      try {
        final ManualBattleRoom? currentRoom = _activeRoom;
        if (currentRoom == null || !currentRoom.isWaiting) {
          return;
        }

        _error = 'No opponent found. Starting AI fallback...';
        notifyListeners();

        final bool started = await _onlineService.activateBotFallback(
          roomId: currentRoom.id,
          hostUsername: _currentUser!.username,
          botName: 'AI Corsair',
          botMaxHealth: 30,
          botAttackPower: 10,
        );
        if (!started) {
          _error = 'Still waiting for opponent. You can tap "Start vs AI now".';
          notifyListeners();
          _botFallbackTimer = Timer(const Duration(seconds: 5), () {
            final ManualBattleRoom? refreshRoom = _activeRoom;
            if (refreshRoom != null) {
              _scheduleBotFallbackIfNeeded(refreshRoom);
            }
          });
          return;
        }
        _error = null;
        notifyListeners();
      } on Exception catch (e) {
        _error = e.toString().replaceFirst('Exception: ', '');
        notifyListeners();
        return;
      }
    });
  }

  void _scheduleBotTurnIfNeeded(ManualBattleRoom room) {
    if (!room.isActive ||
        !room.isBotMatch ||
        room.currentTurn != room.botName) {
      _botTurnTimer?.cancel();
      _botTurnTimer = null;
      return;
    }

    if (_botTurnTimer != null && _botTurnTimer!.isActive) {
      return;
    }

    _botTurnTimer = Timer(const Duration(seconds: 1), () async {
      try {
        await _onlineService.performBotTurn(
          roomId: room.id,
          botName: room.botName!,
        );
      } on Exception {
        return;
      }
    });
  }

  void _cancelBotTimers() {
    _botFallbackTimer?.cancel();
    _botTurnTimer?.cancel();
    _botFallbackTimer = null;
    _botTurnTimer = null;
  }

  void _handleRoomEventPopup(ManualBattleRoom room) {
    if (_currentUser == null || room.eventLog.isEmpty) {
      return;
    }

    final String latestEvent = room.eventLog.first;
    if (_lastRoomEvent == null) {
      _lastRoomEvent = latestEvent;
      return;
    }
    if (_lastRoomEvent == latestEvent) {
      return;
    }

    _lastRoomEvent = latestEvent;

    final String me = _currentUser!.username;
    if (latestEvent.startsWith('$me ')) {
      return;
    }

    if (latestEvent.contains('attacked (')) {
      final RegExp coordPattern = RegExp(r'\((\d+),\s*(\d+)\)');
      final RegExpMatch? match = coordPattern.firstMatch(latestEvent);
      final bool wasHit = latestEvent.contains('Hit!');
      final bool wasMiss = latestEvent.contains('Miss.');
      if (match != null) {
        if (wasHit) {
          _flashMessage =
              'Direct hit on your ship at (${match.group(1)}, ${match.group(2)})!';
        } else if (wasMiss) {
          _flashMessage =
              'Enemy missed at (${match.group(1)}, ${match.group(2)}).';
        } else {
          _flashMessage =
              'Enemy salvo at (${match.group(1)}, ${match.group(2)})!';
        }
      } else {
        if (wasHit) {
          _flashMessage = 'Enemy attack hit your ship!';
        } else if (wasMiss) {
          _flashMessage = 'Enemy attack missed.';
        } else {
          _flashMessage = 'Enemy launched an attack!';
        }
      }
      return;
    }

    if (latestEvent.contains('moved boat')) {
      _flashMessage = 'Opponent moved their ship!';
      return;
    }

    if (latestEvent.contains('bought health')) {
      _flashMessage = 'Opponent bought health (+10 HP)!';
      return;
    }
  }

  Future<void> _handleWinReward(ManualBattleRoom room) async {
    if (_currentUser == null ||
        !room.isFinished ||
        room.winner != _currentUser!.username) {
      return;
    }
    if (_rewardedRoomIds.contains(room.id)) {
      return;
    }

    _rewardedRoomIds.add(room.id);
    final UserProfile updated = _currentUser!.copyWith(
      coins: _currentUser!.coins + 120,
    );
    await _persistProfile(updated);
  }

  Future<void> _startRealtimeFriendFeatures() async {
    if (_currentUser == null) {
      return;
    }
    if (!FirebaseBootstrap.isReady) {
      _friendOnlineStatus = <String, bool>{};
      _incomingChallenges = <ManualBattleRoom>[];
      return;
    }

    await _onlineService.setPresence(
      username: _currentUser!.username,
      isOnline: true,
    );
    _startPresenceHeartbeat();
    _watchFriendPresence();
    _watchIncomingChallenges();
  }

  void _startPresenceHeartbeat() {
    _presenceHeartbeatTimer?.cancel();
    if (_currentUser == null || !FirebaseBootstrap.isReady) {
      return;
    }

    _presenceHeartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      final String? username = _currentUser?.username;
      if (username == null) {
        return;
      }
      unawaited(_onlineService.setPresence(username: username, isOnline: true));
    });
  }

  void handleAppLifecycleState(AppLifecycleState state) {
    final String? username = _currentUser?.username;
    if (username == null || !FirebaseBootstrap.isReady) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      unawaited(_onlineService.setPresence(username: username, isOnline: true));
      _startPresenceHeartbeat();
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _presenceHeartbeatTimer?.cancel();
      _presenceHeartbeatTimer = null;
      unawaited(
        _onlineService.setPresence(username: username, isOnline: false),
      );
    }
  }

  void _watchFriendPresence() {
    _presenceSubscription?.cancel();
    _presenceSubscription = null;

    if (_currentUser == null || !FirebaseBootstrap.isReady) {
      _friendOnlineStatus = <String, bool>{};
      return;
    }

    final List<String> friends = List<String>.from(_currentUser!.friends);
    if (friends.isEmpty) {
      _friendOnlineStatus = <String, bool>{};
      notifyListeners();
      return;
    }

    _presenceSubscription = _onlineService
        .watchFriendsPresence(friends)
        .listen(
          (Map<String, bool> state) {
            _friendOnlineStatus = state;
            notifyListeners();
          },
          onError: (Object error) {
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  void _watchIncomingChallenges() {
    _challengeSubscription?.cancel();
    _challengeSubscription = null;

    if (_currentUser == null || !FirebaseBootstrap.isReady) {
      _incomingChallenges = <ManualBattleRoom>[];
      return;
    }

    _challengeSubscription = _onlineService
        .watchIncomingChallenges(_currentUser!.username)
        .listen(
          (List<ManualBattleRoom> rooms) {
            for (final ManualBattleRoom newRoom in rooms) {
              final bool alreadyExists = _incomingChallenges
                  .any((ManualBattleRoom r) => r.id == newRoom.id);
              if (!alreadyExists) {
                unawaited(
                  _notificationService.showBattleChallengeReceivedNotification(
                    newRoom.player1,
                  ),
                );
              }
            }
            _incomingChallenges = rooms;
            notifyListeners();
          },
          onError: (Object error) {
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  void _setBusy(bool busy) {
    _isBusy = busy;
    notifyListeners();
  }

  @override
  void dispose() {
    final String? username = _currentUser?.username;
    if (username != null && FirebaseBootstrap.isReady) {
      unawaited(
        _onlineService.setPresence(username: username, isOnline: false),
      );
    }
    _cancelBotTimers();
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
    _roomSubscription?.cancel();
    _presenceSubscription?.cancel();
    _challengeSubscription?.cancel();
    super.dispose();
  }
}
