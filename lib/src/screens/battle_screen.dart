import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

import '../models/manual_battle_room.dart';
import '../state/app_controller.dart';
import '../widgets/battle_widgets.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  GridPoint? _selectedMove;
  GridPoint? _selectedAttack;
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );
  bool _handledMatchEnd = false;

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handleMatchFinished(BuildContext context, ManualBattleRoom room) {
    if (!room.isFinished) {
      _handledMatchEnd = false;
      return;
    }
    if (_handledMatchEnd) {
      return;
    }
    _handledMatchEnd = true;

    final String me = widget.controller.currentUser?.username ?? '';
    final bool isWinner = room.winner == me;
    if (isWinner) {
      _confettiController.play();
      SystemSound.play(SystemSoundType.click);
    } else {
      SystemSound.play(SystemSoundType.alert);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      final NavigatorState navigator = Navigator.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isWinner
                ? 'Victory! Returning to Command Deck.'
                : 'Defeat! Returning to Command Deck.',
          ),
        ),
      );

      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      await widget.controller.leaveCurrentRoom();
      if (!mounted) return;
      navigator.popUntil((Route<dynamic> route) => route.isFirst);
    });
  }

  SnackBar _buildThemedSnackBar(BuildContext context, String message) {
    final bool isHit = message.toLowerCase().contains('hit');
    final bool isAlert =
        message.toLowerCase().contains('opponent') ||
        message.toLowerCase().contains('attacked');

    final IconData icon = isHit
        ? Icons.local_fire_department
        : isAlert
        ? Icons.campaign
        : Icons.sports_esports;

    final Color bg = isHit
        ? const Color(0xFF8E1D1D)
        : isAlert
        ? const Color(0xFF0C3D69)
        : const Color(0xFF0B2D4B);

    final double topInset =
        MediaQuery.paddingOf(context).top + kToolbarHeight + 10;
    final double bottomInset = MediaQuery.sizeOf(context).height * 0.42;

    return SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(14, topInset, 14, bottomInset),
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 2),
      content: Row(
        children: <Widget>[
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFlashMessageIfAny(BuildContext context) {
    final String? message = widget.controller.flashMessage;
    if (message == null || message.isEmpty) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(_buildThemedSnackBar(context, message));
      widget.controller.consumeFlashMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        _showFlashMessageIfAny(context);
        final ManualBattleRoom? room = widget.controller.activeRoom;
        if (room == null) {
          return _buildMatchmaking(context);
        }
        _handleMatchFinished(context, room);
        // Ensure leaving the screen triggers server-side leave and local cleanup
        return WillPopScope(
          onWillPop: () async {
            try {
              await widget.controller.leaveCurrentRoom();
            } catch (_) {}
            return true;
          },
          child: _buildMatchRoom(context, room),
        );
      },
    );
  }

  Widget _buildMatchmaking(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        forceMaterialTransparency: true,
        title: const Text('BattleBoats Multiplayer'),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/match_find.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: const Color(0x59000000)),
          Center(
            child: Card(
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Ready for Naval Battle',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tap once to enter matchmaking. You will automatically join an available opponent or create a new waiting match.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: widget.controller.isBusy
                            ? null
                            : () async {
                                final ScaffoldMessengerState messenger =
                                    ScaffoldMessenger.of(context);
                                final bool ok = await widget.controller
                                    .quickMatch();
                                if (!mounted) return;
                                if (!ok) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        widget.controller.error ??
                                            'Matchmaking failed. Check connection.',
                                      ),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.rocket_launch),
                        label: Text(
                          widget.controller.isBusy
                              ? 'Finding Match...'
                              : 'Find Match',
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back'),
                      ),
                      if (widget.controller.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            widget.controller.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchRoom(BuildContext context, ManualBattleRoom room) {
    final String me = widget.controller.currentUser!.username;
    final bool myTurn = room.currentTurn == me && room.isActive;
    final bool isP1 = room.isPlayerOne(me);
    final GridPoint myBoat = room.boatFor(me);
    final List<String> missesOnMe = room.missesOn(me);
    final List<String> missesByMe = room.missesBy(me);
    final String enemyName = isP1
        ? (room.player2 ?? 'Waiting...')
        : room.player1;
    final double width = MediaQuery.sizeOf(context).width;
    final double gridSide = ((width - 40) / 2).clamp(125, 190).toDouble();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        forceMaterialTransparency: true,
        title: Text('Battle vs $enemyName'),
        leading: Builder(
          builder: (BuildContext ctx) {
            final NavigatorState navigator = Navigator.of(ctx);
            return IconButton(
              icon: const Icon(Icons.home),
              onPressed: () async {
                try {
                  await widget.controller.leaveCurrentRoom();
                } catch (_) {}
                if (!mounted) return;
                navigator.pop();
              },
            );
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fight.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: <Widget>[
            Container(color: const Color(0x59000000)),
            Align(
              alignment: Alignment.topCenter,
              child: IgnorePointer(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 26,
                  gravity: 0.15,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  10,
                  8 + MediaQuery.paddingOf(context).top + kToolbarHeight,
                  10,
                  8,
                ),
                child: Column(
                  children: <Widget>[
                    RepaintBoundary(
                      child: ScorePanel(
                        me: me,
                        enemy: enemyName,
                        myHealth: room.healthFor(me),
                        enemyHealth: isP1
                            ? room.player2Health
                            : room.player1Health,
                        myCoins: room.coinsFor(me),
                        enemyCoins: isP1 ? room.player2Coins : room.player1Coins,
                        myHits: room.hitsFor(me),
                        enemyHits: isP1 ? room.player2Hits : room.player1Hits,
                        turnLabel: room.isWaiting
                            ? 'Waiting for opponent... AI fallback in 20s'
                            : room.isFinished
                                ? 'Winner: ${room.winner ?? 'Unknown'}'
                                : myTurn
                                    ? 'Your Turn'
                                    : 'Opponent Turn',
                      ),
                    ),
                    if (room.isWaiting && room.player1 == me)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: FilledButton.icon(
                          onPressed: widget.controller.isBusy
                              ? null
                              : widget.controller.startBotMatchNow,
                          icon: const Icon(Icons.smart_toy),
                          label: const Text('Start vs AI now'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: gridSide + 36,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: OceanGrid(
                              title: 'Your Ocean',
                              boat: myBoat,
                              missedMarks: missesOnMe,
                              selected: _selectedMove,
                              onTapCell: room.isActive
                                  ? (GridPoint point) {
                                      setState(() => _selectedMove = point);
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TargetGrid(
                              title: 'Enemy Ocean',
                              missedMarks: missesByMe,
                              selected: _selectedAttack,
                              revealBoat: room.isFinished,
                              revealedBoat: room.enemyBoatFor(me),
                              onTapCell: room.isActive
                                  ? (GridPoint point) {
                                      setState(() => _selectedAttack = point);
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    RepaintBoundary(
                      child: ActionPanel(
                        canAct: myTurn,
                        canMove: myTurn && _selectedMove != null,
                        canAttack: myTurn && _selectedAttack != null,
                        onMove: () => widget.controller.moveBoat(
                          _selectedMove!.x,
                          _selectedMove!.y,
                        ),
                        onAttack: () => widget.controller.attack(
                          _selectedAttack!.x,
                          _selectedAttack!.y,
                        ),
                        onBuyHealth: widget.controller.buyHealthInMatch,
                      ),
                    ),
                    if (widget.controller.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          widget.controller.error!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
