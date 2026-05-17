import 'package:flutter/material.dart';

import '../state/app_controller.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final user = controller.currentUser!;
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Captain Stats'),
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
                      image: AssetImage('assets/images/upgrades_page.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              RepaintBoundary(child: Container(color: const Color(0x66000000))),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16 + MediaQuery.paddingOf(context).top + kToolbarHeight,
                  16,
                  16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      RepaintBoundary(child: _HeroPanel(user: user)),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _StatCard(
                              icon: Icons.monetization_on,
                              label: 'Coins',
                              value: '${user.coins}',
                              accent: const Color(0xFFFFD54F),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.favorite,
                              label: 'Max HP',
                              value: '${user.maxHealth}',
                              accent: const Color(0xFFFF6E6E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _StatCard(
                              icon: Icons.whatshot,
                              label: 'Attack',
                              value: '${user.attackPower}',
                              accent: const Color(0xFF7CFCB2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.group,
                              label: 'Crew',
                              value: '${user.friends.length}',
                              accent: const Color(0xFF8AB4F8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _LevelBar(
                        label: 'Hull Level',
                        level: user.hullLevel,
                        subtitle: 'Upgrade cost: ${user.hullUpgradeCost}',
                        accent: const Color(0xFF8AD7FF),
                      ),
                      const SizedBox(height: 12),
                      _LevelBar(
                        label: 'Cannon Level',
                        level: user.cannonLevel,
                        subtitle: 'Upgrade cost: ${user.cannonUpgradeCost}',
                        accent: const Color(0xFFFFA26B),
                      ),
                      const SizedBox(height: 14),
                      Card(
                        color: const Color(0x52FFFFFF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0x80FFFFFF)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: <Widget>[
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(0xFF0E2238),
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Captain ${user.username}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'A quick status board for your ship and crew.',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0x66FFFFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x99FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: const DecorationImage(
                  image: AssetImage('assets/images/pfp.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Command Status',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fleet ready with ${user.friends.length} allies on deck.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0x52FFFFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x80FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({
    required this.label,
    required this.level,
    required this.subtitle,
    required this.accent,
  });

  final String label;
  final int level;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double progress = (level / 10).clamp(0.0, 1.0);
    return Card(
      color: const Color(0x52FFFFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x80FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Lv $level',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}