import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/features/home/domain/dashboard_stats.dart';
import 'package:frontend/ui/assets.dart';

// --- WIDGET : RECENT ACTIVITY ---
class RecentActivityPanel extends StatelessWidget {
  const RecentActivityPanel({required this.statsFuture, super.key});

  final Future<DashboardStats> statsFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Icon(Icons.error_outline));
        }
        final activities =
            snapshot.data?.recentActivities ?? const <RecentActivity>[];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.bar_chart,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              AppTextsHome.recentActivityTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (activities.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Aucune activité récente',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                )
              else
                ...activities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final activity = entry.value;
                  final iconData = _iconForType(activity.type);
                  final iconColor = _colorForType(activity.type);
                  final title = _titleForType(activity.type);

                  return Column(
                    children: [
                      if (index > 0)
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      _activityItem(
                        iconData,
                        iconColor,
                        title,
                        activity.subtitle,
                        activity.elapsedLabel.isNotEmpty
                            ? activity.elapsedLabel
                            : _relativeTime(activity.occurredAt),
                      ),
                    ],
                  );
                }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _activityItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'report':
        return Icons.warning_amber_rounded;
      case 'survey':
        return Icons.poll_outlined;
      case 'event':
        return Icons.calendar_month_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'report':
        return AppColors.error;
      case 'survey':
        return AppColors.primary;
      case 'event':
        return AppColors.warning;
      default:
        return AppColors.secondaryText;
    }
  }

  String _titleForType(String type) {
    switch (type) {
      case 'report':
        return AppTextsHome.newReportActivity;
      case 'survey':
        return AppTextsHome.newSurveyActivity;
      case 'event':
        return AppTextsHome.eventAddedActivity;
      default:
        return AppTextsHome.recentActivityTitle;
    }
  }

  String _relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime.toLocal());
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} j';
  }
}

// --- WIDGET : USEFUL INFO ---
class UsefulInfoPanel extends StatelessWidget {
  const UsefulInfoPanel({super.key, required this.statsFuture});
  final Future<DashboardStats> statsFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final roadsCount = stats?.unresolvedReportsRoads.toString() ?? '-';
        final cleanlinessCount =
            stats?.unresolvedReportsCleanliness.toString() ?? '-';
        final lightingCount =
            stats?.unresolvedReportsLighting.toString() ?? '-';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        AppTextsHome.usefulInfoTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 160,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
                    _mapStatItem(
                      Icons.lightbulb_outline,
                      AppColors.info,
                      AppTextsHome.faultyLighting,
                      lightingCount,
                    ),
                    const SizedBox(height: 12),
                    _mapStatItem(
                      Icons.delete_outline,
                      AppColors.success,
                      AppTextsHome.overflowingBins,
                      cleanlinessCount,
                    ),
                    const SizedBox(height: 12),
                    _mapStatItem(
                      Icons.warning_amber,
                      AppColors.warning,
                      AppTextsHome.roadDamage,
                      roadsCount,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
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
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.textDark)),
        ),
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
