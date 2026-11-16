import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'common.dart';

class MapPin {
  const MapPin(this.point, this.label, {this.onTap});
  final LatLng point;
  final String label;
  final VoidCallback? onTap;
}

class JejuMap extends StatelessWidget {
  const JejuMap({
    super.key,
    this.pins = const [],
    this.line = const [],
    this.onTap,
    this.height = 340,
    this.center,
    this.revision = '',
  });
  final List<MapPin> pins;
  final List<LatLng> line;
  final ValueChanged<LatLng>? onTap;
  final double height;
  final LatLng? center;
  final String revision;
  @override
  Widget build(BuildContext context) {
    final points = [...pins.map((p) => p.point), ...line];
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          key: ValueKey(revision),
          options: MapOptions(
            initialCenter:
                center ??
                (points.isEmpty ? const LatLng(33.38, 126.55) : points.first),
            initialZoom: points.isEmpty ? 10 : 12,
            initialCameraFit: points.length >= 2
                ? CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(points),
                    padding: const EdgeInsets.all(40),
                    maxZoom: 15,
                  )
                : null,
            onTap: (_, point) => onTap?.call(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'kr.oreumit.jeju_tour_flutter',
              maxNativeZoom: 19,
            ),
            if (line.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(points: line, strokeWidth: 5, color: moss),
                ],
              ),
            MarkerLayer(
              markers: pins
                  .map(
                    (pin) => Marker(
                      point: pin.point,
                      width: 42,
                      height: 48,
                      child: Tooltip(
                        message: pin.label,
                        child: InkWell(
                          onTap: pin.onTap,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Text(
                              pin.label.length > 3 ? '●' : pin.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => openLink(
                    context,
                    'https://www.openstreetmap.org/copyright',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
