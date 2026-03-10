import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/features/home/domain/dashboard_stats.dart';
import 'package:frontend/ui/assets.dart';

// --- WIDGET : RECENT ACTIVITY ---
class RecentActivityPanel extends StatelessWidget {
  const RecentActivityPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(AppTextsHome.recentActivityTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(AppTextsHome.seeAll, style: TextStyle(color: AppColors.textGrey)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _activityItem(Icons.warning, Colors.redAccent, AppTextsHome.newReportActivity, 'Rue Victor Hugo', '20 min'),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _activityItem(Icons.poll, AppColors.primary, AppTextsHome.newVoteActivity, 'Sondage transports', '1 heure'),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _activityItem(Icons.calendar_month, Colors.orangeAccent, AppTextsHome.eventAddedActivity, 'Festival local', '2 heures'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _activityItem(IconData icon, Color color, String title, String subtitle, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        ],
      ),
    );
  }
}

// --- WIDGET : USEFUL INFO ---
class UsefulInfoPanel extends StatelessWidget {
  final Future<DashboardStats> statsFuture;

  const UsefulInfoPanel({super.key, required this.statsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final roadsCount = stats?.unresolvedReportsRoads.toString() ?? '-';
        final cleanlinessCount = stats?.unresolvedReportsCleanliness.toString() ?? '-';
        final lightingCount = stats?.unresolvedReportsLighting.toString() ?? '-';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(AppTextsHome.usefulInfoTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ],
                ),
              ),
              Container(
                height: 160,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage(AppAssets.map),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _mapStatItem(Icons.warning_amber, Colors.orange, AppTextsHome.roadDamage, roadsCount),
                    const SizedBox(height: 12),
                    _mapStatItem(Icons.delete_outline, Colors.red, AppTextsHome.overflowingBins, cleanlinessCount),
                    const SizedBox(height: 12),
                    _mapStatItem(Icons.lightbulb_outline, AppColors.primary, AppTextsHome.faultyLighting, lightingCount),
                    const SizedBox(height: 20),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _mapStatItem(IconData icon, Color color, String label, String count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textDark))),
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
      ],
    );
  }
}