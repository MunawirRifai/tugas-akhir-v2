import 'dart:async';
import 'dart:convert';

import '../../domain/models/smart_cart_item.dart';

class DirectionsService {
  final String apiKey;

  const DirectionsService({
    this.apiKey = '',
  });

  static const Duration _mockLatency = Duration(milliseconds: 520);

  /*
    Service ini sengaja dibuat sebagai MOCK BACK-END RESPONSE.

    Keputusan arsitektur:
    - Google Maps Directions API dan Smart Cart Sorting final dieksekusi di BE.
    - FE tidak perlu langsung hit Google Directions API pada tahap ini.
    - FE cukup menerima response dari BE berupa:
      1. donor prioritas pertama,
      2. polylinePoints,
      3. estimasi jarak,
      4. estimasi waktu,
      5. metadata performa jaringan.

    Nanti ketika endpoint BE siap, method getRouteToTopPriorityDonor()
    cukup diganti agar memanggil endpoint:

    POST /directions

    Format request ideal ke BE:
    {
      "origin": {"latitude": -6.9730, "longitude": 107.6300},
      "destination": {"latitude": -6.9680, "longitude": 107.6342},
      "mode": "driving",
      "alternatives": true,
      "optimizeWaypoints": true
    }
  */

  Future<DirectionsRouteData> getRouteToTopPriorityDonor({
    required SmartGeoPoint origin,
    required SmartGeoPoint destination,
    required PickupTransportMode mode,
    List<SmartGeoPoint> waypoints = const <SmartGeoPoint>[],
    bool alternatives = true,
    bool optimizeWaypoints = true,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    await Future<void>.delayed(_mockLatency);

    final Map<String, dynamic> mockBackendJson = _buildMockBackendResponse(
      origin: origin,
      destination: destination,
      mode: mode,
      waypoints: waypoints,
      alternatives: alternatives,
      optimizeWaypoints: optimizeWaypoints,
      startedAt: DateTime.now(),
    );

    stopwatch.stop();

    final int responseBytes = utf8.encode(
      jsonEncode(mockBackendJson),
    ).length;

    final Map<String, dynamic> data = _mapOf(
      mockBackendJson['data'],
    );

    return DirectionsRouteData.fromBackendMap({
      ...data,
      'networkLatencyMs': stopwatch.elapsedMilliseconds,
      'responseBytes': responseBytes,
    });
  }

  Future<DirectionsRouteData> getMockRouteFromBackend({
    required SmartGeoPoint origin,
    required SmartGeoPoint destination,
    required PickupTransportMode mode,
  }) {
    return getRouteToTopPriorityDonor(
      origin: origin,
      destination: destination,
      mode: mode,
      alternatives: true,
      optimizeWaypoints: true,
    );
  }

  Map<String, dynamic> _buildMockBackendResponse({
    required SmartGeoPoint origin,
    required SmartGeoPoint destination,
    required PickupTransportMode mode,
    required List<SmartGeoPoint> waypoints,
    required bool alternatives,
    required bool optimizeWaypoints,
    required DateTime startedAt,
  }) {
    final double directDistanceKm = origin.distanceKmTo(destination);

    final double routeDistanceKm = _estimateRoadDistanceKm(
      directDistanceKm,
      mode,
    );

    final int distanceMeters = (routeDistanceKm * 1000).round();

    final int durationSeconds = _estimateDurationSeconds(
      distanceKm: routeDistanceKm,
      mode: mode,
    );

    final List<SmartGeoPoint> polylinePoints = _mockPolylinePoints(
      origin: origin,
      destination: destination,
    );

    return {
      'success': true,
      'message': 'Mock directions generated from Front-End service.',
      'data': {
        'priorityDonor': {
          'foodId': 'mock-priority-001',
          'foodName': _mockPriorityFoodName(mode),
          'donorName': 'Donatur Prioritas',
          'latitude': destination.latitude,
          'longitude': destination.longitude,
          'condition': 'segera dihabiskan',
          'score': _mockScore(
            directDistanceKm: directDistanceKm,
          ),
        },
        'polylinePoints': polylinePoints
            .map(
              (point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              },
            )
            .toList(),
        'distanceText': _formatDistance(distanceMeters),
        'durationText': _formatDuration(durationSeconds),
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
        'mode': mode.apiValue,
        'alternatives': alternatives,
        'optimizeWaypoints': optimizeWaypoints,
        'waypointCount': waypoints.length,
        'mockedAt': startedAt.toIso8601String(),
      },
    };
  }

  List<SmartGeoPoint> _mockPolylinePoints({
    required SmartGeoPoint origin,
    required SmartGeoPoint destination,
  }) {
    final double latDiff = destination.latitude - origin.latitude;
    final double lngDiff = destination.longitude - origin.longitude;

    return [
      origin,
      SmartGeoPoint(
        latitude: origin.latitude + (latDiff * 0.18),
        longitude: origin.longitude + (lngDiff * 0.10),
      ),
      SmartGeoPoint(
        latitude: origin.latitude + (latDiff * 0.36),
        longitude: origin.longitude + (lngDiff * 0.28),
      ),
      SmartGeoPoint(
        latitude: origin.latitude + (latDiff * 0.54),
        longitude: origin.longitude + (lngDiff * 0.46),
      ),
      SmartGeoPoint(
        latitude: origin.latitude + (latDiff * 0.73),
        longitude: origin.longitude + (lngDiff * 0.70),
      ),
      SmartGeoPoint(
        latitude: origin.latitude + (latDiff * 0.88),
        longitude: origin.longitude + (lngDiff * 0.86),
      ),
      destination,
    ];
  }

  double _estimateRoadDistanceKm(
    double directDistanceKm,
    PickupTransportMode mode,
  ) {
    final double multiplier = switch (mode) {
      PickupTransportMode.walking => 1.16,
      PickupTransportMode.driving => 1.28,
      PickupTransportMode.transit => 1.42,
    };

    final double estimatedDistance = directDistanceKm * multiplier;

    if (estimatedDistance < 0.15) {
      return 0.15;
    }

    return estimatedDistance;
  }

  int _estimateDurationSeconds({
    required double distanceKm,
    required PickupTransportMode mode,
  }) {
    final double averageSpeedKmPerHour = switch (mode) {
      PickupTransportMode.walking => 4.4,
      PickupTransportMode.driving => 24.0,
      PickupTransportMode.transit => 16.0,
    };

    final double durationHours = distanceKm / averageSpeedKmPerHour;
    final int baseSeconds = (durationHours * 3600).round();

    final int bufferSeconds = switch (mode) {
      PickupTransportMode.walking => 90,
      PickupTransportMode.driving => 180,
      PickupTransportMode.transit => 420,
    };

    return baseSeconds + bufferSeconds;
  }

  double _mockScore({
    required double directDistanceKm,
  }) {
    const int yellowBaseScore = 100;

    return yellowBaseScore - (directDistanceKm * 10);
  }

  String _mockPriorityFoodName(PickupTransportMode mode) {
    switch (mode) {
      case PickupTransportMode.walking:
        return 'Paket Makanan Terdekat';
      case PickupTransportMode.driving:
        return 'Paket Donasi Prioritas';
      case PickupTransportMode.transit:
        return 'Paket Pickup Transit';
    }
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }

    return '$meters m';
  }

  String _formatDuration(int seconds) {
    final int minutes = (seconds / 60).ceil();

    if (minutes < 60) {
      return '$minutes menit';
    }

    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '$hours jam';
    }

    return '$hours jam $remainingMinutes menit';
  }

  Map<String, dynamic> _mapOf(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(
          key.toString(),
          mapValue,
        ),
      );
    }

    return <String, dynamic>{};
  }
}

/*
  Compatibility class.

  File lama sebelumnya memakai nama GoogleDirectionsService.
  Class ini dipertahankan agar migrasi bertahap tidak langsung merusak
  controller/page yang belum dipindah import-nya.
*/
class GoogleDirectionsService extends DirectionsService {
  const GoogleDirectionsService({
    super.apiKey,
  });
}