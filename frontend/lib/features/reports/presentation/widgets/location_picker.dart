import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    this.initialLocation,
    required this.onLocationChanged,
  });

  final LatLng? initialLocation;
  final ValueChanged<LatLng> onLocationChanged;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng? _pickedLocation;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
  }

  void _selectLocation(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
    widget.onLocationChanged(position);
  }

  Future<void> _openMap() async {
    final pickedLocation = await showDialog<LatLng>(
      context: context,
      builder: (context) => MapDialog(
        initialLocation: _pickedLocation,
      ),
    );

    if (pickedLocation != null) {
      _selectLocation(pickedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _openMap,
          icon: const Icon(Icons.map),
          label: const Text('Select Location'),
        ),
        if (_pickedLocation != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Lat: ${_pickedLocation!.latitude.toStringAsFixed(5)}, Lng: ${_pickedLocation!.longitude.toStringAsFixed(5)}',
            ),
          ),
      ],
    );
  }
}

class MapDialog extends StatefulWidget {
  const MapDialog({super.key, this.initialLocation});

  final LatLng? initialLocation;

  @override
  State<MapDialog> createState() => _MapDialogState();
}

class _MapDialogState extends State<MapDialog> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onTap(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Location'),
      content: SizedBox(
        height: 400,
        width: 400,
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: widget.initialLocation ?? const LatLng(45.5017, -73.5673), // Montreal
            zoom: 11.0,
          ),
          onTap: _onTap,
          markers: {
            if (_pickedLocation != null)
              Marker(
                markerId: const MarkerId('picked-location'),
                position: _pickedLocation!,
              ),
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_pickedLocation),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
