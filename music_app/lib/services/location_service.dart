import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  /// Obtiene el país actual del dispositivo usando GPS
  /// Retorna el nombre del país o null si no se pudo determinar
  static Future<String?> getCurrentCountry() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Verificar que el GPS esté habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Obtener posición actual con timeout de 10s y baja precisión para ahorrar batería
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Convertir coordenadas a país usando IP-API gratuita (no necesita API key)
      final url =
          'http://ip-api.com/json/?lat=${position.latitude}&lon=${position.longitude}&fields=country';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final country = data['country'] as String?;
        if (country != null && country.isNotEmpty) {
          return country;
        }
      }
    } catch (e) {
      // Silencioso - retorna null si falla
    }

    return null;
  }
}
