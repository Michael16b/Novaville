class DashboardStats {
  final int pendingReports;
  final int activeSurveys;
  final int eventsThisWeek;
  final int unresolvedReportsRoads;
  final int unresolvedReportsLighting;
  final int unresolvedReportsCleanliness;
  final int totalCitizens;
  final int reportsThisMonth;
  final int pollParticipationRate;

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
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      pendingReports: json['pending_reports'] as int,
      activeSurveys: json['active_surveys'] as int,
      eventsThisWeek: json['events_this_week'] as int,
      unresolvedReportsRoads: json['unresolved_reports_roads'] as int,
      unresolvedReportsLighting: json['unresolved_reports_lighting'] as int,
      unresolvedReportsCleanliness: json['unresolved_reports_cleanliness'] as int,
      totalCitizens: json['total_citizens'] as int,
      reportsThisMonth: json['reports_this_month'] as int,
      pollParticipationRate: json['poll_participation_rate'] as int,
    );
  }
}
