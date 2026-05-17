import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../services/ad_service.dart';

class UpgradesScreen extends StatefulWidget {
  const UpgradesScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<UpgradesScreen> createState() => _UpgradesScreenState();
}

class _UpgradesScreenState extends State<UpgradesScreen> {
  @override
  Widget build(BuildContext context) {
    final AppController controller = widget.controller;
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final user = controller.currentUser!;
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Boat Upgrades'),
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
              RepaintBoundary(child: Container(color: const Color(0x59000000))),
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
                      Card(
                        color: const Color(0x52FFFFFF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0x80FFFFFF)),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.monetization_on,
                            size: 34,
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Upgrade Treasury',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            'Coins available: ${user.coins}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        color: const Color(0x52FFFFFF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0x80FFFFFF)),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.ondemand_video,
                            size: 34,
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Watch Ad for Coins',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text(
                            'Watch an ad to receive 50 coins',
                            style: TextStyle(color: Colors.white),
                          ),
                          trailing: FilledButton(
                            style: FilledButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              await AdService.initialize();
                              AdService.loadRewardedAd();
                              final bool granted = await AdService.showRewardedAd(
                                onEarnedReward: (reward) async {
                                  await controller.grantCoins(50);
                                },
                              );
                              if (!mounted) return;
                              if (granted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('You earned 50 coins!')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ad not ready, try again.')),
                                );
                              }
                            },
                            child: const Text('Watch'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        color: const Color(0x52FFFFFF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0x80FFFFFF)),
                        ),
                        child: ListTile(
                          leading: Image.asset(
                            'assets/images/armor.png',
                            width: 62,
                            height: 62,
                          ),
                          title: Text(
                            'Hull Level ${user.hullLevel}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            'Max HP: ${user.maxHealth} • Upgrade cost: ${user.hullUpgradeCost}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: FilledButton(
                            style: FilledButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            onPressed: controller.upgradeHull,
                            child: const Text('Upgrade'),
                          ),
                        ),
                      ),
                      Card(
                        color: const Color(0x52FFFFFF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0x80FFFFFF)),
                        ),
                        child: ListTile(
                          leading: Image.asset(
                            'assets/images/firepower.png',
                            width: 62,
                            height: 62,
                          ),
                          title: Text(
                            'Cannon Level ${user.cannonLevel}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            'Attack: ${user.attackPower} • Upgrade cost: ${user.cannonUpgradeCost}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: FilledButton(
                            style: FilledButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            onPressed: controller.upgradeCannon,
                            child: const Text('Upgrade'),
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
