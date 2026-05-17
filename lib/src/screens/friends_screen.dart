import 'package:flutter/material.dart';

import '../models/manual_battle_room.dart';
import '../state/app_controller.dart';
import 'battle_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _friendController = TextEditingController();
  bool _openedBattle = false;

  @override
  void initState() {
    super.initState();
    widget.controller.refreshRequests();
  }

  @override
  void dispose() {
    _friendController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    await widget.controller.sendFriendRequest(_friendController.text);
    if (!mounted) return;

    final String message = widget.controller.error == null
        ? 'Friend request sent.'
        : widget.controller.error!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    if (widget.controller.error == null) {
      _friendController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        final user = widget.controller.currentUser!;
        final ManualBattleRoom? room = widget.controller.activeRoom;
        if (room != null && !_openedBattle) {
          _openedBattle = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BattleScreen(controller: widget.controller),
              ),
            );
          });
        }
        if (room == null) {
          _openedBattle = false;
        }

        final List<String> sortedFriends = List<String>.from(user.friends)
          ..sort((String a, String b) {
            final bool aOnline = widget.controller.isFriendOnline(a);
            final bool bOnline = widget.controller.isFriendOnline(b);
            if (aOnline != bOnline) {
              return aOnline ? -1 : 1;
            }
            return a.toLowerCase().compareTo(b.toLowerCase());
          });

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Friends'),
            leading: IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Stack(
            children: <Widget>[
              RepaintBoundary(
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/friendsb.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              RepaintBoundary(child: Container(color: const Color(0x59000000))),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16 + MediaQuery.paddingOf(context).top + kToolbarHeight,
                  16,
                  16,
                ),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _friendController,
                      decoration: InputDecoration(
                        labelText: 'Add captain by username',
                        suffixIcon: IconButton(
                          onPressed: widget.controller.isBusy
                              ? null
                              : _sendRequest,
                          icon: const Icon(Icons.person_add),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Incoming Challenges',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.controller.incomingChallenges.isEmpty)
                      Card(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          child: const Text('No incoming battle challenges.'),
                        ),
                      )
                    else
                      Column(
                        children: widget.controller.incomingChallenges
                            .map(
                              (ManualBattleRoom room) => Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          const Icon(Icons.sports_kabaddi),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '${room.player1} challenged you',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: <Widget>[
                                          FilledButton(
                                            onPressed: () => widget.controller
                                                .acceptChallenge(room.id),
                                            child: const Text('Accept'),
                                          ),
                                          OutlinedButton(
                                            onPressed: () => widget.controller
                                                .declineChallenge(room.id),
                                            child: const Text('Decline'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Incoming Requests',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.controller.incomingRequests.isEmpty)
                      Card(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          child: const Text('No incoming requests.'),
                        ),
                      )
                    else
                      Column(
                        children: widget.controller.incomingRequests
                            .map(
                              (String requester) => Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          const Icon(
                                            Icons.notifications_active,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              requester,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: <Widget>[
                                          FilledButton(
                                            onPressed: () => widget.controller
                                                .acceptRequest(requester),
                                            child: const Text('Accept'),
                                          ),
                                          OutlinedButton(
                                            onPressed: () => widget.controller
                                                .rejectRequest(requester),
                                            child: const Text('Reject'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Fleet Friends (${user.friends.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        primary: false,
                        padding: EdgeInsets.zero,
                        itemCount: sortedFriends.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String friend = sortedFriends[index];
                          final bool isOnline = widget.controller
                              .isFriendOnline(friend);
                          return Card(
                            child: ListTile(
                              leading: Stack(
                                clipBehavior: Clip.none,
                                children: <Widget>[
                                  const Icon(Icons.account_circle, size: 30),
                                  Positioned(
                                    right: -1,
                                    bottom: -1,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: isOnline
                                            ? Colors.lightGreenAccent
                                            : Colors.grey,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(friend),
                              subtitle: Text(
                                isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: isOnline
                                      ? Colors.lightGreenAccent
                                      : Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: isOnline
                                  ? FilledButton(
                                      onPressed: widget.controller.isBusy
                                          ? null
                                          : () async {
                                              final ScaffoldMessengerState
                                              messenger = ScaffoldMessenger.of(
                                                context,
                                              );
                                              final bool ok = await widget
                                                  .controller
                                                  .challengeFriend(friend);
                                              if (!mounted) return;
                                              final String message = ok
                                                  ? 'Challenge sent to $friend.'
                                                  : (widget.controller.error ??
                                                        'Failed to send challenge.');
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(message),
                                                ),
                                              );
                                            },
                                      child: const Text('Battle'),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
