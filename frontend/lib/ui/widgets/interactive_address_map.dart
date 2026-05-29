import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend/config/app_config.dart';
import 'package:frontend/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Interactive OpenStreetMap widget used to browse or select an address.
class InteractiveAddressMap extends StatefulWidget {
  /// Creates an interactive map.
  const InteractiveAddressMap({
    this.height = 220,
    this.initialCenter,
    this.initialZoom = 13,
    this.markers = const [],
    this.onAddressSelected,
    super.key,
  });

  static const LatLng _parisCenter = LatLng(48.8566, 2.3522);

  /// Fixed map height.
  final double height;

  /// Initial map center. Defaults to the city postal code, then Paris.
  final LatLng? initialCenter;

  /// Initial zoom level.
  final double initialZoom;

  /// Markers rendered on the map.
  final List<InteractiveAddressMapMarker> markers;

  /// Called with the reverse-geocoded address when the user taps the map.
  final ValueChanged<String>? onAddressSelected;

  @override
  State<InteractiveAddressMap> createState() => _InteractiveAddressMapState();
}

class _InteractiveAddressMapState extends State<InteractiveAddressMap> {
  static const double _minZoom = 5;
  static const double _maxZoom = 19;
  static final Map<String, LatLng?> _postalCodeCenterCache = {};

  late final MapController _mapController;
  late double _zoom;
  LatLng? _resolvedDefaultCenter;
  LatLng? _selectedPoint;
  bool _isResolvingAddress = false;

  bool get _isSelectable => widget.onAddressSelected != null;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _zoom = widget.initialZoom;
    _loadConfiguredDefaultCenter();
  }

  @override
  void didUpdateWidget(covariant InteractiveAddressMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCenter != oldWidget.initialCenter) {
      _moveToDefaultCenter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter =
        widget.initialCenter ??
        _resolvedDefaultCenter ??
        InteractiveAddressMap._parisCenter;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Listener(
          onPointerSignal: _handlePointerSignal,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: widget.initialZoom,
                  minZoom: _minZoom,
                  maxZoom: _maxZoom,
                  initialCameraFit: _initialCameraFit(),
                  onTap: _isSelectable
                      ? (_, point) => _selectPoint(point)
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.novaville',
                  ),
                  if (widget.markers.isNotEmpty)
                    MarkerLayer(
                      markers: widget.markers
                          .map(
                            (marker) => Marker(
                              point: marker.point,
                              height: 36,
                              alignment: Alignment.topCenter,
                              child: Tooltip(
                                message: marker.tooltip,
                                child: GestureDetector(
                                  onTap: marker.onTap,
                                  child: _MapPinMarker(color: marker.color),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  if (_selectedPoint != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPoint!,
                          width: 42,
                          height: 42,
                          child: const Icon(
                            Icons.location_pin,
                            color: AppColors.error,
                            size: 42,
                          ),
                        ),
                      ],
                    ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _MapZoomControls(
                  onZoomIn: () => _changeZoom(1),
                  onZoomOut: () => _changeZoom(-1),
                ),
              ),
              if (_isResolvingAddress)
                const Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.overlay,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _usesDefaultCenter =>
      widget.initialCenter == null && widget.markers.isEmpty;

  Future<void> _loadConfiguredDefaultCenter() async {
    if (!_usesDefaultCenter) return;

    final center = await _fetchCityCenter();
    if (!mounted || center == null) return;

    _resolvedDefaultCenter = center;
    _moveToDefaultCenter();
  }

  void _moveToDefaultCenter() {
    final center =
        widget.initialCenter ??
        _resolvedDefaultCenter ??
        InteractiveAddressMap._parisCenter;
    _mapController.move(center, _zoom);
  }

  Future<LatLng?> _fetchCityCenter() async {
    try {
      final usefulInfo = await _fetchUsefulInfo();
      final postalCode = usefulInfo['postal_code']?.toString().trim() ?? '';
      if (postalCode.isEmpty) return null;

      final city = usefulInfo['city']?.toString().trim() ?? '';
      final cacheKey = '$postalCode|$city'.toLowerCase();
      if (_postalCodeCenterCache.containsKey(cacheKey)) {
        return _postalCodeCenterCache[cacheKey];
      }

      final center = await _geocodePostalCode(
        postalCode: postalCode,
        city: city,
      );
      _postalCodeCenterCache[cacheKey] = center;
      return center;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _fetchUsefulInfo() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/useful-info/'),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) return const {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<LatLng?> _geocodePostalCode({
    required String postalCode,
    required String city,
  }) async {
    final byPostalCode = await _searchPostalCode(postalCode: postalCode);
    if (byPostalCode != null || city.isEmpty) return byPostalCode;

    return _searchPostalCode(postalCode: postalCode, city: city);
  }

  Future<LatLng?> _searchPostalCode({
    required String postalCode,
    String? city,
  }) async {
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

  Future<LatLng?> _searchPosition(Uri uri) async {
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body) as List<dynamic>;
    if (decoded.isEmpty) return null;

    final firstResult = decoded.first as Map<String, dynamic>;
    final latitude = double.tryParse(firstResult['lat']?.toString() ?? '');
    final longitude = double.tryParse(firstResult['lon']?.toString() ?? '');
    if (latitude == null || longitude == null) return null;

    return LatLng(latitude, longitude);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (
      PointerSignalEvent resolvedEvent,
    ) {
      final scrollEvent = resolvedEvent as PointerScrollEvent;
      final zoomDelta = scrollEvent.scrollDelta.dy < 0 ? 0.75 : -0.75;
      _changeZoom(zoomDelta);
    });
  }

  CameraFit? _initialCameraFit() {
    if (widget.initialCenter != null) return null;
    if (widget.markers.isEmpty) return null;
    if (widget.markers.length == 1) {
      return CameraFit.coordinates(
        coordinates: [widget.markers.first.point],
        maxZoom: 14,
      );
    }

    final points = widget.markers.map((marker) => marker.point).toList();
    final latitudes = points.map((point) => point.latitude);
    final longitudes = points.map((point) => point.longitude);
    final southWest = LatLng(
      latitudes.reduce((a, b) => a < b ? a : b),
      longitudes.reduce((a, b) => a < b ? a : b),
    );
    final northEast = LatLng(
      latitudes.reduce((a, b) => a > b ? a : b),
      longitudes.reduce((a, b) => a > b ? a : b),
    );

    return CameraFit.bounds(
      bounds: LatLngBounds(southWest, northEast),
      padding: const EdgeInsets.all(28),
      maxZoom: 14,
    );
  }

  void _changeZoom(double delta) {
    final nextZoom = (_zoom + delta).clamp(_minZoom, _maxZoom);
    _zoom = nextZoom;
    _mapController.move(_mapController.camera.center, nextZoom);
  }

  Future<void> _selectPoint(LatLng point) async {
    setState(() {
      _selectedPoint = point;
      _isResolvingAddress = true;
    });

    try {
      final address = await _reverseGeocode(point);
      if (!mounted || address == null || address.isEmpty) return;
      widget.onAddressSelected?.call(address);
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingAddress = false;
        });
      }
    }
  }

  Future<String?> _reverseGeocode(LatLng point) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': point.latitude.toStringAsFixed(6),
      'lon': point.longitude.toStringAsFixed(6),
      'addressdetails': '1',
      'accept-language': 'fr',
    });

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return _formatAddress(decoded);
  }

  String? _formatAddress(Map<String, dynamic> json) {
    final rawAddress = json['address'];
    if (rawAddress is Map<String, dynamic>) {
      final houseNumber = rawAddress['house_number']?.toString().trim();
      final road = _firstAddressPart(rawAddress, const [
        'road',
        'pedestrian',
        'footway',
        'path',
        'residential',
      ]);
      if (houseNumber != null &&
          houseNumber.isNotEmpty &&
          road != null &&
          road.isNotEmpty) {
        return '$houseNumber $road';
      }
    }

    final displayName = json['display_name']?.toString().trim();
    if (displayName == null || displayName.isEmpty) return null;
    return displayName.split(',').take(2).join(',').trim();
  }

  String? _firstAddressPart(Map<String, dynamic> address, List<String> keys) {
    for (final key in keys) {
      final value = address[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}

/// Marker rendered by [InteractiveAddressMap].
class InteractiveAddressMapMarker {
  /// Creates a map marker.
  const InteractiveAddressMapMarker({
    required this.point,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  /// Marker geographic position.
  final LatLng point;

  /// Marker display color.
  final Color color;

  /// Tooltip displayed on hover.
  final String tooltip;

  /// Called when the marker is clicked.
  final VoidCallback? onTap;
}

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({required this.onZoomIn, required this.onZoomOut});

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Zoomer',
            visualDensity: VisualDensity.compact,
            onPressed: onZoomIn,
            icon: const Icon(Icons.add, size: 20),
          ),
          const SizedBox(width: 32, child: Divider(height: 1)),
          IconButton(
            tooltip: 'Dézoomer',
            visualDensity: VisualDensity.compact,
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove, size: 20),
          ),
        ],
      ),
    );
  }
}

class _MapPinMarker extends StatelessWidget {
  const _MapPinMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          bottom: 1,
          child: Container(
            width: 10,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Icon(
          Icons.location_on,
          color: Colors.black.withValues(alpha: 0.28),
          size: 31,
        ),
        Positioned(
          top: 1,
          child: Icon(Icons.location_on, color: color, size: 29),
        ),
        Positioned(
          top: 9,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.88),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
