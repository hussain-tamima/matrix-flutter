import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/location/repo/location_repo.dart';
import 'package:geolocator/geolocator.dart';

class LocationRepoImpl implements LocationRepo {
  LocationRepoImpl(this._store);

  final MatrixStore _store;

  @override
  bool get sharingEnabled => _store.preferences.locationSharingEnabled;

  @override
  Future<void> share(String roomId, String label) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are turned off');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission was denied');
    }
    final position = await Geolocator.getCurrentPosition();
    await _store.sendMessage(
      roomId: roomId,
      body: label,
      kind: TimelineEventKind.location,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
