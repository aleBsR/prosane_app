import 'package:connectivity_plus/connectivity_plus.dart';

/// Expone online/offline a partir de connectivity_plus.
/// `fromStream` permite inyectar el stream crudo en tests.
class ConnectivityService {
  ConnectivityService.fromStream(Stream<List<ConnectivityResult>> raw)
      : onlineStream =
            raw.map((r) => r.isNotEmpty && !r.contains(ConnectivityResult.none));

  factory ConnectivityService() =>
      ConnectivityService.fromStream(Connectivity().onConnectivityChanged);

  final Stream<bool> onlineStream;
}
