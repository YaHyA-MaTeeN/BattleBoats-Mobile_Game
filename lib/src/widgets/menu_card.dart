import 'package:flutter/material.dart';

class MenuCard extends StatelessWidget {
  const MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double iconSize = (constraints.maxWidth * 0.72).clamp(
                92.0,
                128.0,
              );
              final double titleSize = (constraints.maxWidth * 0.13).clamp(
                18.0,
                22.0,
              );
              final double subtitleSize = (constraints.maxWidth * 0.095).clamp(
                14.0,
                17.0,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: iconSize,
                    width: iconSize,
                    child: FittedBox(fit: BoxFit.contain, child: icon),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      shadows: const <Shadow>[
                        Shadow(color: Color(0xCC000000), blurRadius: 3),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w600,
                      shadows: const <Shadow>[
                        Shadow(color: Color(0xCC000000), blurRadius: 3),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
