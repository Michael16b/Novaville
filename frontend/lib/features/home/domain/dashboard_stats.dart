class RecentActivity {
  const RecentActivity({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.occurredAt,
    required this.elapsedSeconds,
    required this.elapsedLabel,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: (json['type'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      subtitle: (json['subtitle'] as String?) ?? '',
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      elapsedSeconds: (json['elapsed_seconds'] as int?) ?? 0,
      elapsedLabel: (json['elapsed_label'] as String?) ?? '',
    );
  }
  final String type;
  final String title;
  final String subtitle;
  final DateTime occurredAt;
  final int elapsedSeconds;
  final String elapsedLabel;
}

class DashboardStats {
  DashboardStats({
    required this.pendingReports,
    required this.activeSurveys,
    required this.eventsThisWeek,
    required this.unresolvedReportsRoads,
    required this.unresolvedReportsLighting,
    required this.unresolvedReportsCleanliness,
    required this.totalCitizens,
    required this.reportsThisMonth,
    required this.pollParticipationRate,
    required this.recentActivities,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      pendingReports: json['pending_reports'] as int,
      activeSurveys: json['active_surveys'] as int,
      eventsThisWeek: json['events_this_week'] as int,
      unresolvedReportsRoads: json['unresolved_reports_roads'] as int,
      unresolvedReportsLighting: json['unresolved_reports_lighting'] as int,
      unresolvedReportsCleanliness:
          json['unresolved_reports_cleanliness'] as int,
      totalCitizens: json['total_citizens'] as int,
      reportsThisMonth: json['reports_this_month'] as int,
      pollParticipationRate: json['poll_participation_rate'] as int,
      recentActivities:
          (json['recent_activities'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (item) => RecentActivity.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }
  final int pendingReports;
  final int activeSurveys;
  final int eventsThisWeek;
  final int unresolvedReportsRoads;
  final int unresolvedReportsLighting;
  final int unresolvedReportsCleanliness;
  final int totalCitizens;
  final int reportsThisMonth;
  final int pollParticipationRate;
  final List<RecentActivity> recentActivities;
}
