import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'common.dart';

class MapPin {
  const MapPin(
    this.point,
    this.label, {
    this.onTap,
    this.color = accent,
    this.size = 42,
  });
  final LatLng point;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double size;
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
    this.fitPoints,
  });
  final List<MapPin> pins;
  final List<LatLng> line;
  final ValueChanged<LatLng>? onTap;
  final double height;
  final LatLng? center;
  final String revision;

  /// 카메라를 맞출 좌표. 지정하지 않으면 모든 핀과 선을 기준으로 맞춘다.
  final List<LatLng>? fitPoints;
  @override
  Widget build(BuildContext context) {
    final points = fitPoints ?? [...pins.map((p) => p.point), ...line];
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
                      width: pin.size,
                      height: pin.size + 6,
                      child: Tooltip(
                        message: pin.label,
                        child: InkWell(
                          onTap: pin.onTap,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: pin.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: pin.size < 30 ? 2 : 3,
                              ),
                            ),
                            child: Text(
                              pin.label.length > 3 ? '●' : pin.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: pin.size < 30 ? 9 : null,
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
