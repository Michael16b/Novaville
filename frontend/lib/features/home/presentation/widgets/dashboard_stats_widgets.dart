import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/features/home/domain/dashboard_stats.dart';

// --- WIDGET : TOP STATS ROW ---
class TopStatsRow extends StatelessWidget {
  final Future<DashboardStats> statsFuture;

  const TopStatsRow({super.key, required this.statsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const TopStatsSkeleton();
        } else if (snapshot.hasError) {
          return Row(
            children: [
              _statPill(Icons.circle, Colors.redAccent, '-', AppTextsHome.pendingReports),
              const SizedBox(width: 16),
              _statPill(Icons.circle, AppColors.primary, '-', AppTextsHome.activePolls),
              const SizedBox(width: 16),
              _statPill(Icons.calendar_today, Colors.orangeAccent, '-', AppTextsHome.eventsThisWeek),
            ],
          );
        } else if (snapshot.hasData) {
          final stats = snapshot.data!;
          return Row(
            children: [
              _statPill(Icons.circle, Colors.redAccent, stats.pendingReports.toString(), AppTextsHome.pendingReports),
              const SizedBox(width: 16),
              _statPill(Icons.circle, AppColors.primary, stats.activeSurveys.toString(), AppTextsHome.activePolls),
              const SizedBox(width: 16),
              _statPill(Icons.calendar_today, Colors.orangeAccent, stats.eventsThisWeek.toString(), AppTextsHome.eventsThisWeek),
            ],
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _statPill(IconData icon, Color color, String number, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(number, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ],
      ),
    );
  }
}

// --- WIDGET : BOTTOM STATS BAR ---
class BottomStatsBar extends StatelessWidget {
  final Future<DashboardStats> statsFuture;

  const BottomStatsBar({super.key, required this.statsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BottomStatsSkeleton();
        }

        final stats = snapshot.data;
        final totalCitizens = stats?.totalCitizens.toString() ?? '-';
        final reportsThisMonth = stats?.reportsThisMonth.toString() ?? '-';
        final pollParticipationRate = stats?.pollParticipationRate.toString() ?? '-';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.people, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.textDark, fontSize: 16),
                      children: [
                        const TextSpan(text: AppTextsHome.platformUsagePrefix),
                        TextSpan(text: totalCitizens, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const TextSpan(text: AppTextsHome.platformUsageSuffix),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.shade400.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.warning_amber, color: Colors.red.shade400, size: 20),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.textDark, fontSize: 15),
                      children: [
                        TextSpan(text: reportsThisMonth, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const TextSpan(text: AppTextsHome.reportsMonthSuffix),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.pie_chart, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text('${AppTextsHome.pollParticipationPrefix}$pollParticipationRate %', style: const TextStyle(color: AppColors.textDark, fontSize: 15)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// SKELETONS
// ==========================================

class TopStatsSkeleton extends StatefulWidget {
  const TopStatsSkeleton({super.key});

  @override
  State<TopStatsSkeleton> createState() => _TopStatsSkeletonState();
}

class _TopStatsSkeletonState extends State<TopStatsSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseController.value;
        final barColor = Color.lerp(
          Colors.grey.shade300,
          Colors.grey.shade100,
          pulseValue,
        )!;

        return Row(
          children: [
            _buildSkeletonPill(barColor),
            const SizedBox(width: 16),
            _buildSkeletonPill(barColor),
            const SizedBox(width: 16),
            _buildSkeletonPill(barColor),
          ],
        );
      },
    );
  }

  Widget _buildSkeletonPill(Color color) {
    return Container(
      height: 48,
      width: 250,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}


class BottomStatsSkeleton extends StatefulWidget {
  const BottomStatsSkeleton({super.key});

  @override
  State<BottomStatsSkeleton> createState() => _BottomStatsSkeletonState();
}

class _BottomStatsSkeletonState extends State<BottomStatsSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseController.value;
        final barColor = Color.lerp(
          Colors.grey.shade200,
          Colors.grey.shade50,
          pulseValue,
        )!;
        final iconColor = Color.lerp(
          Colors.grey.shade300,
          Colors.grey.shade100,
          pulseValue,
        )!;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSkeletonItem(iconColor, barColor),
              _buildSkeletonItem(iconColor, barColor),
              _buildSkeletonItem(iconColor, barColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonItem(Color iconColor, Color barColor) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 16,
          width: 120,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}