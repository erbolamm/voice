/// EJEMPLO DE CLIENTE FLUTTER PARA VIBEVOICE
/// Equivalente en Dart de lo que está haciendo el backend

import 'dart:async';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Función principal: Conectarse al servidor VibeVoice y recibir audio en streaming
/// 
/// En Python (backend), esto es lo que hace la función `stream()` en app.py
Future<void> vibeVoiceTextToSpeech({
  required String text,
  required String voiceName,
  double cfgScale = 1.5,
  int inferenceSteps = 5,
}) async {
  // PASO 1: Crear conexión WebSocket (como StreamController.listen())
  final String wsUrl = 'ws://localhost:3000/stream'
      '?text=${Uri.encodeComponent(text)}'
      '&voice=$voiceName'
      '&cfg=$cfgScale'
      '&steps=$inferenceSteps';

  print('🎙️ Conectando a: $wsUrl');

  try {
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    // PASO 2: Escuchar el stream de audio (como stream.listen())
    // El backend emite chunks de audio en tiempo real
    print('✓ Conectado! Escuchando stream de audio...');

    channel.stream.listen(
      (data) {
        // 'data' es un chunk de audio PCM16
        // En Flutter harías: _audioPlayer.play(data)
        print('🔊 Recibido chunk de audio: ${data.length} bytes');
      },
      onError: (error) {
        print('❌ Error en stream: $error');
      },
      onDone: () {
        print('✅ Stream completado. Audio generado completamente.');
      },
    );
  } catch (e) {
    print('❌ Error al conectar: $e');
  }
}

/// COMPARACIÓN CON FLUTTER STREAMS
/// ================================
///
/// En Flutter, esto sería como:
///
/// ```dart
/// class VibeVoiceService {
///   late StreamController<Uint8List> _audioController;
///   
///   Stream<Uint8List> generateSpeech(String text, String voice) {
///     _audioController = StreamController<Uint8List>();
///     
///     // El backend hace lo mismo: emite chunks de audio
///     // como _audioController.add(audioChunk)
///     
///     return _audioController.stream;
///   }
///   
///   // En tu UI:
///   @override
///   Widget build(BuildContext context) {
///     return StreamBuilder<Uint8List>(
///       stream: service.generateSpeech('Hello', 'Carter'),
///       builder: (context, snapshot) {
///         if (snapshot.hasData) {
///           // Reproduce el audio mientras llega
///           playAudio(snapshot.data!);
///         }
///         return Text('Generando audio...');
///       },
///     );
///   }
/// }
/// ```
///
/// Lo que hace VibeVoice es EXACTAMENTE ESO:
/// - El backend genera tokens de audio continuamente
/// - Los emite en chunks pequeños (como StreamController.add())
/// - El cliente recibe en tiempo real (como stream.listen())
/// - Puedes reproducir mientras se genera (streaming real-time)

/// PARÁMETROS DISPONIBLES (como configurar un servicio)
/// ====================================================
class VibeVoiceConfig {
  /// Voces disponibles (como opciones en un Dropdown)
  static const List<String> voces = [
    'en-Carter_man',    // Voz por defecto (recomendada)
    'en-Emma_woman',
    'en-Frank_man',
    'en-Grace_woman',
    'en-Mike_man',
    'en-Davis_man',
    'de-Spk0_man',
    'fr-Spk0_man',
    'ja-Spk0_man',
    // ... más voces disponibles
  ];

  /// CFG Scale: controla cuánto "sigue" al texto
  /// 1.0 = Sin seguimiento (audio genérico)
  /// 1.5 = Balance perfecto (RECOMENDADO)
  /// 3.0 = Sigue mucho el texto (puede ser menos natural)
  static const double cfgScaleDefault = 1.5;

  /// Pasos de inferencia: más = mejor calidad, más lento
  /// 5 = Muy rápido, buena calidad (RECOMENDADO)
  /// 10 = Mejor calidad, más lento
  static const int inferenceStepsDefault = 5;

  /// Latencia esperada en ms (primera vez que escuchas audio)
  static const int firstAudioLatencyMs = 300; // ~300ms
}

/// EJEMPLO DE USO EN TU APP FLUTTER
/// =================================
class VibeVoiceDemo {
  Future<void> demoBásico() async {
    // 1️⃣ Texto a convertir
    const String texto = 'Hola, este es un test de síntesis de voz en tiempo real';

    // 2️⃣ Voz a usar
    const String voz = 'en-Carter_man';

    // 3️⃣ Llamar la función (como hacer un GET request)
    await vibeVoiceTextToSpeech(
      text: texto,
      voiceName: voz,
      cfgScale: 1.5,
      inferenceSteps: 5,
    );

    // El audio empieza a llegar en ~300ms
    // Puedes reproducirlo mientras se genera
  }
}

/// MODO "BUS" vs "REALTIME"
/// =========================
/// 
/// ANTES (Modo BUS):
/// - El servidor estaba corriendo pero sin procesar nada
/// - Era como tener una EventBus que escucha pero nadie envía eventos
/// 
/// AHORA (Modo REALTIME):
/// - El servidor está activo y esperando peticiones WebSocket
/// - Cuando envías texto → genera audio continuamente
/// - Es como un StreamController que emite datos en tiempo real
/// 
/// Lo que necesitas hacer:
/// 1. Enviar texto al WebSocket
/// 2. Escuchar los chunks de audio que llegan
/// 3. Reproducirlos en paralelo (streaming real-time)

void main() {
  // Esto es lo que harías en tu app Flutter:
  final demo = VibeVoiceDemo();
  demo.demoBásico();
}
