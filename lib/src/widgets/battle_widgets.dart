import 'package:flutter/material.dart';

import '../models/manual_battle_room.dart';

class ScorePanel extends StatelessWidget {
  const ScorePanel({
    required this.me,
    required this.enemy,
    required this.myHealth,
    required this.enemyHealth,
    required this.myCoins,
    required this.enemyCoins,
    required this.myHits,
    required this.enemyHits,
    required this.turnLabel,
    super.key,
  });

  final String me;
  final String enemy;
  final int myHealth;
  final int enemyHealth;
  final int myCoins;
  final int enemyCoins;
  final int myHits;
  final int enemyHits;
  final String turnLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '$me  HP:$myHealth  Coins:$myCoins  Hits:$myHits',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Text(
                    '$enemy  HP:$enemyHealth  Coins:$enemyCoins  Hits:$enemyHits',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              turnLabel,
              style: const TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionPanel extends StatelessWidget {
  const ActionPanel({
    required this.canAct,
    required this.canMove,
    required this.canAttack,
    required this.onMove,
    required this.onAttack,
    required this.onBuyHealth,
    super.key,
  });

  final bool canAct;
  final bool canMove;
  final bool canAttack;
  final VoidCallback onMove;
  final VoidCallback onAttack;
  final VoidCallback onBuyHealth;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              onPressed: canMove ? onMove : null,
              icon: const Icon(Icons.open_with),
              label: const Text('Move'),
            ),
            FilledButton.icon(
              onPressed: canAttack ? onAttack : null,
              icon: const Icon(Icons.gps_fixed),
              label: const Text('Attack'),
            ),
            OutlinedButton.icon(
              onPressed: canAct ? onBuyHealth : null,
              icon: const Icon(Icons.favorite),
              label: const Text('Buy Health'),
            ),
          ],
        ),
      ),
    );
  }
}

class OceanGrid extends StatelessWidget {
  const OceanGrid({
    required this.title,
    required this.boat,
    required this.missedMarks,
    required this.selected,
    required this.onTapCell,
    super.key,
  });

  final String title;
  final GridPoint boat;
  final List<String> missedMarks;
  final GridPoint? selected;
  final ValueChanged<GridPoint>? onTapCell;

  @override
  Widget build(BuildContext context) {
    final Set<String> missedSet = missedMarks.toSet();

    return GridFrame(
      title: title,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ManualBattleRoom.gridSize * ManualBattleRoom.gridSize,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ManualBattleRoom.gridSize,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        ),
        itemBuilder: (BuildContext context, int index) {
          final int x = index ~/ ManualBattleRoom.gridSize;
          final int y = index % ManualBattleRoom.gridSize;
          final GridPoint point = GridPoint.cached(x, y);
          final bool isBoat = point.key == boat.key;
          final bool isMiss = missedSet.contains(point.key);
          final bool isSelected = selected?.key == point.key;

          final Color bg = isMiss
              ? const Color(0xFF1D4E89)
              : isBoat
              ? const Color(0xFF1A6B8D)
              : const Color(0xFF175F96);

          return Cell(
            bg: bg,
            isSelected: isSelected,
            selectedColor: Colors.cyanAccent,
            onTap: onTapCell == null ? null : () => onTapCell!(point),
            child: isBoat
                ? const Icon(Icons.sailing, size: 16, color: Colors.white)
                : isMiss
                ? const Icon(Icons.water_drop, size: 14, color: Colors.white)
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class TargetGrid extends StatelessWidget {
  const TargetGrid({
    required this.title,
    required this.missedMarks,
    required this.selected,
    required this.revealBoat,
    required this.revealedBoat,
    required this.onTapCell,
    super.key,
  });

  final String title;
  final List<String> missedMarks;
  final GridPoint? selected;
  final bool revealBoat;
  final GridPoint revealedBoat;
  final ValueChanged<GridPoint>? onTapCell;

  @override
  Widget build(BuildContext context) {
    final Set<String> missedSet = missedMarks.toSet();

    return GridFrame(
      title: title,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ManualBattleRoom.gridSize * ManualBattleRoom.gridSize,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ManualBattleRoom.gridSize,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        ),
        itemBuilder: (BuildContext context, int index) {
          final int x = index ~/ ManualBattleRoom.gridSize;
          final int y = index % ManualBattleRoom.gridSize;
          final GridPoint point = GridPoint.cached(x, y);
          final bool isMiss = missedSet.contains(point.key);
          final bool isSelected = selected?.key == point.key;
          final bool isRevealedBoat =
              revealBoat && point.key == revealedBoat.key;

          final Color bg = isMiss
              ? const Color(0xFF2A5E93)
              : isRevealedBoat
              ? const Color(0xFF245B7A)
              : const Color(0xFF1D6BA1);

          return Cell(
            bg: bg,
            isSelected: isSelected,
            selectedColor: Colors.orangeAccent,
            onTap: onTapCell == null ? null : () => onTapCell!(point),
            child: isMiss
                ? const Icon(Icons.water_drop, size: 14, color: Colors.white)
                : isRevealedBoat
                ? const Icon(Icons.sailing, size: 16, color: Colors.white)
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class GridFrame extends StatelessWidget {
  const GridFrame({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          // Contain repaint to the grid area to avoid repainting parent widgets
          Expanded(child: RepaintBoundary(child: child)),
        ],
      ),
    );
  }
}

class Cell extends StatelessWidget {
  const Cell({
    required this.bg,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
    required this.child,
    super.key,
  });

  final Color bg;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[bg.withValues(alpha: 0.86), bg],
          ),
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected ? selectedColor : Colors.white12,
            width: isSelected ? 2 : 0.6,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
