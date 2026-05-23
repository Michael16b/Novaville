import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Interactive OpenStreetMap widget used to browse or select an address.
class InteractiveAddressMap extends StatefulWidget {
  /// Creates an interactive map.
  const InteractiveAddressMap({
    this.height = 220,
    this.initialCenter = _defaultCenter,
    this.initialZoom = 13,
    this.onAddressSelected,
    super.key,
  });

  static const LatLng _defaultCenter = LatLng(48.8566, 2.3522);

  /// Fixed map height.
  final double height;

  /// Initial map center.
  final LatLng initialCenter;

  /// Initial zoom level.
  final double initialZoom;

  /// Called with the reverse-geocoded address when the user taps the map.
  final ValueChanged<String>? onAddressSelected;

  @override
  State<InteractiveAddressMap> createState() => _InteractiveAddressMapState();
}

class _InteractiveAddressMapState extends State<InteractiveAddressMap> {
  static const double _minZoom = 5;
  static const double _maxZoom = 19;

  late final MapController _mapController;
  late double _zoom;
  LatLng? _selectedPoint;
  bool _isResolvingAddress = false;

  bool get _isSelectable => widget.onAddressSelected != null;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _zoom = widget.initialZoom;
  }

  @override
  Widget build(BuildContext context) {
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
                  initialCenter: widget.initialCenter,
                  initialZoom: widget.initialZoom,
                  minZoom: _minZoom,
                  maxZoom: _maxZoom,
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
