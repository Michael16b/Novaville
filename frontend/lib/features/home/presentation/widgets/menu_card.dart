import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

enum MenuCardStyle { large, compact }

class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.statValue,
    this.statLabel,
    required this.onTap,
    this.style = MenuCardStyle.large,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? statValue;
  final String? statLabel;
  final VoidCallback onTap;
  final MenuCardStyle style;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.only(
      topLeft: Radius.circular(50),
      topRight: Radius.circular(15),
      bottomRight: Radius.circular(50),
      bottomLeft: Radius.circular(30),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              red: 0,
              green: 0,
              blue: 0,
              alpha: 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.primary,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(
            color: Colors.white.withValues(
              red: 1,
              green: 1,
              blue: 1,
              alpha: 0.1,
            ),
          ),
        ),
        child: InkWell(
          splashColor: Colors.white.withValues(
            red: 1,
            green: 1,
            blue: 1,
            alpha: 0.2,
          ),
          highlightColor: Colors.white.withValues(
            red: 1,
            green: 1,
            blue: 1,
            alpha: 0.1,
          ),
          onTap: onTap,
          child: style == MenuCardStyle.large
              ? _buildLargeCard()
              : _buildCompactCard(),
        ),
      ),
    );
  }

  Widget _buildLargeCard() {
    final hasStat = statValue != null && statLabel != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 320;
        final isVeryCompact = constraints.maxWidth < 240;
        final iconSize = isVeryCompact
            ? 22.0
            : isCompact
            ? 24.0
            : 28.0;
        final titleSize = isVeryCompact
            ? 16.0
            : isCompact
            ? 18.0
            : 21.0;
        final statValueSize = isVeryCompact
            ? 22.0
            : isCompact
            ? 24.0
            : 30.0;
        final statLabelSize = isVeryCompact
            ? 12.0
            : isCompact
            ? 13.0
            : 14.0;
        final contentPadding = isVeryCompact
            ? const EdgeInsets.fromLTRB(18, 18, 18, 16)
            : const EdgeInsets.fromLTRB(22, 22, 22, 18);
        final statPadding = isVeryCompact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

        return Stack(
          children: [
            Positioned(
              bottom: -28,
              left: -16,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(
                    red: 0,
                    green: 0,
                    blue: 0,
                    alpha: 0.04,
                  ),
                ),
              ),
            ),
            Padding(
              padding: contentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isCompact ? 44 : 50,
                    height: isCompact ? 44 : 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        red: 1,
                        green: 1,
                        blue: 1,
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.secondary,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(height: isVeryCompact ? 12 : 18),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const Spacer(),
                  if (hasStat)
                    Container(
                      width: double.infinity,
                      padding: statPadding,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(
                              red: 1,
                              green: 1,
                              blue: 1,
                              alpha: 0.16,
                            ),
                            Colors.white.withValues(
                              red: 1,
                              green: 1,
                              blue: 1,
                              alpha: 0.08,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(
                            red: 1,
                            green: 1,
                            blue: 1,
                            alpha: 0.10,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            statValue!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: statValueSize,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              statLabel!,
                              style: TextStyle(
                                color: Colors.white.withValues(
                                  red: 1,
                                  green: 1,
                                  blue: 1,
                                  alpha: 0.92,
                                ),
                                fontSize: statLabelSize,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactCard() {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
