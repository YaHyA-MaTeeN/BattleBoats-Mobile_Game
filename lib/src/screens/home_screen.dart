import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.controller,
    required this.onOpenFriends,
    required this.onOpenUpgrades,
    required this.onOpenStats,
    required this.onStartBattle,
    super.key,
  });

  final AppController controller;
  final VoidCallback onOpenFriends;
  final VoidCallback onOpenUpgrades;
  final VoidCallback onOpenStats;
  final VoidCallback onStartBattle;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        forceMaterialTransparency: true,
        title: const Text('BattleBoats Command Deck'),
        actions: <Widget>[
          IconButton(
            onPressed: controller.logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          RepaintBoundary(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/command.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          RepaintBoundary(child: Container(color: const Color(0x52000000))),
          Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  32 + MediaQuery.paddingOf(context).top + kToolbarHeight,
                  16,
                  16,
                ),
            child: Column(
              children: <Widget>[
                RepaintBoundary(
                  child: Card(
                    color: const Color(0xF2FFFFFF),
                    child: ListTile(
                      leading: const CircleAvatar(
                        radius: 26,
                        backgroundImage: AssetImage('assets/images/pfp.png'),
                      ),
                      title: Text(
                        'Captain ${user.username}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'Coins: ${user.coins} • Hull Lv ${user.hullLevel} • Cannon Lv ${user.cannonLevel}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      trailing: Text(
                        'Crew: ${user.friends.length}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                if (controller.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      controller.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                        const double crossSpacing = 12;
                        const double mainSpacing = 8;
                        const double aspectRatio = 0.66;
                        final double tileWidth =
                          (constraints.maxWidth - crossSpacing) / 2;
                        final double tileHeight = tileWidth / aspectRatio;
                        final double gridHeight = tileHeight * 2 + mainSpacing;
                        final double rawPad = (constraints.maxHeight - gridHeight) / 2;
                        final double verticalPadding = math.max(8.0, rawPad * 0.45);

                      return GridView.count(
                        primary: false,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          vertical: verticalPadding,
                        ),
                        crossAxisCount: 2,
                        crossAxisSpacing: crossSpacing,
                        mainAxisSpacing: mainSpacing,
                        childAspectRatio: aspectRatio,
                        children: <Widget>[
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onStartBattle,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: LayoutBuilder(
                                  builder: (BuildContext ctx, BoxConstraints c) {
                                    final double size = (c.maxWidth * 0.9).clamp(92.0, 200.0);
                                    return Center(
                                      child: Image.asset(
                                        'assets/images/onlinebattle.png',
                                        width: size,
                                        height: size,
                                        fit: BoxFit.contain,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onOpenFriends,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: LayoutBuilder(
                                  builder: (BuildContext ctx, BoxConstraints c) {
                                    final double size = (c.maxWidth * 0.9).clamp(92.0, 200.0);
                                    return Center(
                                      child: Image.asset(
                                        'assets/images/add_friends.png',
                                        width: size,
                                        height: size,
                                        fit: BoxFit.contain,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onOpenUpgrades,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: LayoutBuilder(
                                  builder: (BuildContext ctx, BoxConstraints c) {
                                    final double size = (c.maxWidth * 0.9).clamp(92.0, 200.0);
                                    return Center(
                                      child: Image.asset(
                                        'assets/images/powerups.png',
                                        width: size,
                                        height: size,
                                        fit: BoxFit.contain,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onOpenStats,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: LayoutBuilder(
                                  builder: (BuildContext ctx, BoxConstraints c) {
                                    final double size = (c.maxWidth * 0.9).clamp(92.0, 200.0);
                                    return Center(
                                      child: Image.asset(
                                        'assets/images/current_stats.png',
                                        width: size,
                                        height: size,
                                        fit: BoxFit.contain,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
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
  }
}
