import 'package:geolocator/geolocator.dart';
import 'api.dart';

Future<Position> currentPosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw ApiException('기기의 위치 서비스를 켜 주세요.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw ApiException('위치 권한을 허용해 주세요. 기상 지도는 직접 지점을 눌러서도 볼 수 있어요.');
  }
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 20),
    ),
  );
}
