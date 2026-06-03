import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  const RouteService._();

  static const Duration _timeout = Duration(seconds: 18);

  /*
    RouteService ini dipakai untuk peta berbasis flutter_map / OpenStreetMap.

    Catatan arsitektur:
    - Untuk Smart Cart + Google Directions, gunakan DirectionsService.
    - Untuk Home Map biasa, service ini tetap aman dipakai sebagai lightweight
      route preview berbasis OSRM public routing.
    - Jika OSRM gagal, service mengembalikan fallback polyline sederhana agar
      UI tetap tidak crash.
  */

  static Future<List<LatLng>> getRoute({
    required LatLng currentLocation,
    required double latitude,
    required double longitude,
    bool allowFallback = true,
  }) {
    return getRouteBetween(
      origin: currentLocation,
      destination: LatLng(latitude, longitude),
      allowFallback: allowFallback,
    );
  }

  static Future<List<LatLng>> getRouteBetween({
    required LatLng origin,
    required LatLng destination,
    bool allowFallback = true,
  }) async {
    if (!_isValidCoordinate(origin) || !_isValidCoordinate(destination)) {
      if (allowFallback) {
        return _fallbackRoute(
          origin: origin,
          destination: destination,
        );
      }

      return <LatLng>[];
    }

    try {
      final Uri uri = _osrmRouteUri(
        origin: origin,
        destination: destination,
      );

      final http.Response response = await http.get(uri).timeout(_timeout);

      debugPrint('ROUTE SERVICE STATUS: ${response.statusCode}');
      debugPrint('ROUTE SERVICE BODY BYTES: ${response.body.length}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (allowFallback) {
          return _fallbackRoute(
            origin: origin,
            destination: destination,
          );
        }

        return <LatLng>[];
      }

      final Map<String, dynamic> body = _decodeJsonMap(response.body);
      final List<LatLng> routePoints = _extractRoutePoints(body);

      if (routePoints.length >= 2) {
        return routePoints;
      }

      if (allowFallback) {
        return _fallbackRoute(
          origin: origin,
          destination: destination,
        );
      }

      return <LatLng>[];
    } on TimeoutException {
      debugPrint('ROUTE SERVICE TIMEOUT');

      if (allowFallback) {
        return _fallbackRoute(
          origin: origin,
          destination: destination,
        );
      }

      return <LatLng>[];
    } catch (error) {
      debugPrint('ROUTE SERVICE ERROR: $error');

      if (allowFallback) {
        return _fallbackRoute(
          origin: origin,
          destination: destination,
        );
      }

      return <LatLng>[];
    }
  }

  static Uri _osrmRouteUri({
    required LatLng origin,
    required LatLng destination,
  }) {
    final String originText =
        '${origin.longitude.toStringAsFixed(6)},${origin.latitude.toStringAsFixed(6)}';

    final String destinationText =
        '${destination.longitude.toStringAsFixed(6)},${destination.latitude.toStringAsFixed(6)}';

    return Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$originText;$destinationText',
      {
        'overview': 'full',
        'geometries': 'geojson',
        'alternatives': 'false',
        'steps': 'false',
      },
    );
  }

  static List<LatLng> _extractRoutePoints(Map<String, dynamic> body) {
    final Object? routesObject = body['routes'];

    if (routesObject is! List || routesObject.isEmpty) {
      return <LatLng>[];
    }

    final Map<String, dynamic> firstRoute = _mapOf(routesObject.first);
    final Map<String, dynamic> geometry = _mapOf(firstRoute['geometry']);

    final Object? coordinatesObject = geometry['coordinates'];

    if (coordinatesObject is! List) {
      return <LatLng>[];
    }

    final List<LatLng> points = [];

    for (final Object? coordinateObject in coordinatesObject) {
      if (coordinateObject is! List || coordinateObject.length < 2) {
        continue;
      }

      final double? longitude = _doubleOf(coordinateObject[0]);
      final double? latitude = _doubleOf(coordinateObject[1]);

      if (latitude == null || longitude == null) {
        continue;
      }

      final LatLng point = LatLng(latitude, longitude);

      if (_isValidCoordinate(point)) {
        points.add(point);
      }
    }

    return points;
  }

  static List<LatLng> _fallbackRoute({
    required LatLng origin,
    required LatLng destination,
  }) {
    final double latitudeDiff = destination.latitude - origin.latitude;
    final double longitudeDiff = destination.longitude - origin.longitude;

    return [
      origin,
      LatLng(
        origin.latitude + latitudeDiff * 0.20,
        origin.longitude + longitudeDiff * 0.14,
      ),
      LatLng(
        origin.latitude + latitudeDiff * 0.42,
        origin.longitude + longitudeDiff * 0.34,
      ),
      LatLng(
        origin.latitude + latitudeDiff * 0.64,
        origin.longitude + longitudeDiff * 0.56,
      ),
      LatLng(
        origin.latitude + latitudeDiff * 0.84,
        origin.longitude + longitudeDiff * 0.78,
      ),
      destination,
    ];
  }

  static bool _isValidCoordinate(LatLng coordinate) {
    return coordinate.latitude.isFinite &&
        coordinate.longitude.isFinite &&
        coordinate.latitude >= -90 &&
        coordinate.latitude <= 90 &&
        coordinate.longitude >= -180 &&
        coordinate.longitude <= 180;
  }

  static Map<String, dynamic> _decodeJsonMap(String rawBody) {
    final String body = rawBody.trim();

    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final Object? decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return <String, dynamic>{};
  }

  static Map<String, dynamic> _mapOf(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(key.toString(), mapValue),
      );
    }

    return <String, dynamic>{};
  }

  static double? _doubleOf(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString());
  }
}