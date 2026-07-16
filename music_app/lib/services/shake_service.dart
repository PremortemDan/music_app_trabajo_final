import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeService {
  static final ShakeService _instance = ShakeService._();
  factory ShakeService() => _instance;
  ShakeService._();

  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime _lastShakeTime = DateTime.now();
  bool _isListening = false;

  /// Umbral de aceleración para detectar sacudida (más alto = menos sensible)
  static const double _shakeThreshold = 35.0;
  /// Tiempo mínimo entre detecciones para evitar múltiples disparos
  static const Duration _shakeCooldown = Duration(seconds: 2);
  /// Número de picos necesarios en 1 segundo para considerarlo una sacudida
  static const int _minPeaks = 2;

  /// Inicia la escucha de sacudidas. Muestra un diálogo al detectar una.
  void startListening(BuildContext context) {
    if (_isListening) return;
    _isListening = true;

    _subscription = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
      (AccelerometerEvent event) {
        final double acceleration = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );

        if (acceleration > _shakeThreshold) {
          final now = DateTime.now();
          if (now.difference(_lastShakeTime) > _shakeCooldown) {
            _lastShakeTime = now;
            _showBugReportDialog(context);
          }
        }
      },
      onError: (error) {
        debugPrint('Error en sensor: $error');
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }

  void _showBugReportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [SizedBox(width: 10),
            Expanded(
              child: Text('¿Encontraste un bug?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sentimos que algo pudo haber salido mal.\n\n'
              'Toma una captura de pantalla y repórtala a nuestro equipo de soporte:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            SelectableText(
              'soporte@resonar.com',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff9bd49f),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}