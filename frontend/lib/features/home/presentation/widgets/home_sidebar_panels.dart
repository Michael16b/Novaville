import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/features/home/domain/dashboard_stats.dart';
import 'package:frontend/features/reports/data/models/problem_type.dart';
import 'package:frontend/features/reports/data/models/report.dart';
import 'package:frontend/features/reports/data/report_repository_factory.dart';
import 'package:frontend/features/useful_info/data/useful_info_repository_factory.dart';
import 'package:frontend/features/useful_info/domain/useful_info.dart';
import 'package:frontend/ui/widgets/interactive_address_map.dart';
import 'package:frontend/ui/widgets/styled_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// --- WIDGET : RECENT ACTIVITY ---
class RecentActivityPanel extends StatelessWidget {
  const RecentActivityPanel({super.key, required this.statsFuture});

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
  final Future<DashboardStats> statsFuture;

  const UsefulInfoPanel({super.key, required this.statsFuture});

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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _RecentReportsMap(),
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

class _RecentReportsMap extends StatefulWidget {
  const _RecentReportsMap();

  @override
  State<_RecentReportsMap> createState() => _RecentReportsMapState();
}

class _RecentReportsMapState extends State<_RecentReportsMap> {
  static final Map<String, LatLng?> _geocodeCache = {};
  static final Map<String, LatLng?> _postalCodeCenterCache = {};

  late final Future<_RecentReportsMapData> _mapDataFuture;

  @override
  void initState() {
    super.initState();
    _mapDataFuture = _loadMapData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RecentReportsMapData>(
      future: _mapDataFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _RecentReportsMapData();

        return InteractiveAddressMap(
          height: 160,
          initialCenter: data.center,
          markers: data.points
              .map(
                (point) => InteractiveAddressMapMarker(
                  point: point.position,
                  color: _problemTypeColor(point.report.problemType),
                  tooltip: point.report.title,
                  onTap: () => _showReportDetails(context, point.report),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Future<_RecentReportsMapData> _loadMapData() async {
    final usefulInfo = await _loadUsefulInfo();
    final center = await _mapCenterFromUsefulInfo(usefulInfo);
    final points = await _loadRecentReportPoints(usefulInfo);
    return _RecentReportsMapData(center: center, points: points);
  }

  Future<UsefulInfo?> _loadUsefulInfo() async {
    try {
      return await createUsefulInfoRepository().getUsefulInfo();
    } catch (_) {
      return null;
    }
  }

  Future<List<_ReportMapPoint>> _loadRecentReportPoints(
    UsefulInfo? usefulInfo,
  ) async {
    final reportsPage = await createReportRepository().listReports(
      ordering: '-created_at',
    );
    final reports = reportsPage.results
        .where((report) => report.address.trim().isNotEmpty)
        .take(10)
        .toList();
    final points = <_ReportMapPoint>[];

    for (final report in reports) {
      final position = await _geocodeAddress(report.address, usefulInfo);
      if (position == null) continue;
      points.add(_ReportMapPoint(report: report, position: position));
    }

    return points;
  }

  Future<LatLng?> _mapCenterFromUsefulInfo(UsefulInfo? usefulInfo) async {
    final postalCode = usefulInfo?.postalCode.trim() ?? '';
    if (postalCode.isEmpty) return null;

    final city = usefulInfo?.city.trim() ?? '';
    final cacheKey = '$postalCode|$city'.toLowerCase();
    if (_postalCodeCenterCache.containsKey(cacheKey)) {
      return _postalCodeCenterCache[cacheKey];
    }

    final center = await _geocodePostalCode(postalCode, city);
    _postalCodeCenterCache[cacheKey] = center;
    return center;
  }

  Future<LatLng?> _geocodePostalCode(String postalCode, String city) async {
    final byPostalCode = await _searchPostalCode(postalCode);
    if (byPostalCode != null || city.isEmpty) return byPostalCode;
    return _searchPostalCode(postalCode, city: city);
  }

  Future<LatLng?> _searchPostalCode(String postalCode, {String? city}) async {
    final structuredUri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'postalcode': postalCode,
      if (city != null && city.isNotEmpty) 'city': city,
      'countrycodes': 'fr',
      'limit': '1',
      'accept-language': 'fr',
    });

    final structuredResult = await _searchPosition(structuredUri);
    if (structuredResult != null) return structuredResult;

    final queryParts = [
      postalCode,
      if (city != null && city.isNotEmpty) city,
      'France',
    ];
    final queryUri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'q': queryParts.join(', '),
      'countrycodes': 'fr',
      'limit': '1',
      'accept-language': 'fr',
    });

    return _searchPosition(queryUri);
  }

  Future<LatLng?> _geocodeAddress(
    String address,
    UsefulInfo? usefulInfo,
  ) async {
    final normalizedAddress = address.trim();
    if (normalizedAddress.isEmpty) return null;
    final searchAddress = _addressWithCityContext(
      normalizedAddress,
      usefulInfo,
    );
    if (_geocodeCache.containsKey(searchAddress)) {
      return _geocodeCache[searchAddress];
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'q': searchAddress,
      'limit': '1',
      'accept-language': 'fr',
    });

    final position = await _searchPosition(uri);
    _geocodeCache[searchAddress] = position;
    return position;
  }

  String _addressWithCityContext(String address, UsefulInfo? usefulInfo) {
    final postalCode = usefulInfo?.postalCode.trim() ?? '';
    if (postalCode.isEmpty) return '$address, France';

    return '$address, $postalCode, France';
  }

  Future<LatLng?> _searchPosition(Uri uri) async {
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body) as List<dynamic>;
    if (decoded.isEmpty) return null;

    final result = decoded.first as Map<String, dynamic>;
    final latitude = double.tryParse(result['lat']?.toString() ?? '');
    final longitude = double.tryParse(result['lon']?.toString() ?? '');
    if (latitude == null || longitude == null) return null;

    return LatLng(latitude, longitude);
  }

  void _showReportDetails(BuildContext context, Report report) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StyledDialog(
        title: report.title,
        icon: _problemTypeIcon(report.problemType),
        accentColor: _problemTypeColor(report.problemType),
        maxWidth: 420,
        actions: [
          StyledDialog.cancelButton(
            label: 'Fermer',
            onPressed: () => Navigator.pop(dialogContext),
          ),
          StyledDialog.primaryButton(
            label: 'Voir',
            icon: Icons.open_in_new,
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go(AppRoutes.reports);
            },
          ),
        ],
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReportDetailLine(
              icon: _problemTypeIcon(report.problemType),
              text: report.problemType.label,
            ),
            const SizedBox(height: 8),
            _ReportDetailLine(
              icon: Icons.flag_outlined,
              text: report.status.label,
            ),
            const SizedBox(height: 8),
            _ReportDetailLine(
              icon: Icons.location_on_outlined,
              text: report.address,
            ),
            const SizedBox(height: 8),
            _ReportDetailLine(
              icon: Icons.person_outline,
              text: _reportUserName(report),
            ),
            const SizedBox(height: 12),
            Text(
              report.description,
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _reportUserName(Report report) {
    final fullName = '${report.user.firstName} ${report.user.lastName}'.trim();
    if (fullName.isNotEmpty) return fullName;
    return report.user.username;
  }

  IconData _problemTypeIcon(ProblemType type) {
    switch (type) {
      case ProblemType.lighting:
        return Icons.lightbulb_outline;
      case ProblemType.cleanliness:
        return Icons.delete_outline;
      case ProblemType.roads:
        return Icons.warning_amber;
    }
  }

  Color _problemTypeColor(ProblemType type) {
    switch (type) {
      case ProblemType.lighting:
        return AppColors.info;
      case ProblemType.cleanliness:
        return AppColors.success;
      case ProblemType.roads:
        return AppColors.warning;
    }
  }
}

class _ReportMapPoint {
  const _ReportMapPoint({required this.report, required this.position});

  final Report report;
  final LatLng position;
}

class _RecentReportsMapData {
  const _RecentReportsMapData({
    this.center,
    this.points = const <_ReportMapPoint>[],
  });

  final LatLng? center;
  final List<_ReportMapPoint> points;
}

class _ReportDetailLine extends StatelessWidget {
  const _ReportDetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondaryText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
