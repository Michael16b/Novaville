import 'package:frontend/features/home/domain/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<DashboardStats> getDashboardStats();
}
