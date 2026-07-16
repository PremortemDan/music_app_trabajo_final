import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Verifica si el dispositivo puede usar autenticación (biométrica, PIN o patrón)
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Obtiene los tipos de biometría disponibles
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Obtiene un mensaje descriptivo de los tipos de autenticación disponibles
  static Future<String> getAvailableAuthDescription() async {
    try {
      final types = await getAvailableBiometrics();
      if (types.isEmpty) {
        final isSupported = await _auth.isDeviceSupported();
        if (isSupported) {
          return 'PIN, patrón o contraseña';
        }
        return 'No disponible';
      }
      final names = types.map((t) {
        switch (t) {
          case BiometricType.face:
            return 'Reconocimiento facial';
          case BiometricType.fingerprint:
            return 'Huella dactilar';
          case BiometricType.iris:
            return 'Iris';
          case BiometricType.strong:
            return 'Biometría fuerte';
          case BiometricType.weak:
            return 'Biometría débil';
        }
      }).toList();
      return '${names.join(", ")}, PIN o patrón';
    } catch (_) {
      return 'No disponible';
    }
  }

  /// Solicita autenticación biométrica (huella, PIN, patrón)
  /// Retorna true si la autenticación fue exitosa
  static Future<bool> authenticate({
    required String reason,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Autenticación requerida',
            cancelButton: 'Cancelar',
            signInHint: 'Usa tu huella, PIN o patrón para continuar',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancelar',
            localizedFallbackTitle: 'Usar código',
          ),
        ],
        biometricOnly: false, // Permitir PIN/patrón también
      );
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Verifica disponibilidad, y si no está disponible retorna false
  /// Retorna true si la autenticación fue exitosa, false si falló o no está disponible
  static Future<bool> authenticateWithCheck({
    required String reason,
  }) async {
    final available = await isAvailable();
    if (!available) {
      return false;
    }
    return await authenticate(reason: reason);
  }
}