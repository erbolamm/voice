/// VibeVoice Flutter Client - Cliente completo para síntesis de voz en tiempo real
///
/// Este archivo contiene todo lo necesario para integrar VibeVoice en tu app Flutter.
///
/// REQUISITOS en pubspec.yaml:
/// ```yaml
/// dependencies:
///   web_socket_channel: ^2.4.0
///   audio_session: ^0.1.14
///   just_audio: ^0.9.36
/// ```

import 'dart:async';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// ============================================================================
/// CONFIGURACIÓN - Como un fichero config.dart en tu app
/// ============================================================================

class VibeVoiceConfig {
  /// URL base del servidor VibeVoice
  static const String baseUrl = 'ws://localhost:3000';

  /// Voces disponibles en el servidor
  static const Map<String, String> voces = {
    'Carter': 'en-Carter_man',
    'Emma': 'en-Emma_woman',
    'Frank': 'en-Frank_man',
    'Grace': 'en-Grace_woman',
    'Mike': 'en-Mike_man',
    'Davis': 'en-Davis_man',
    'Alemán (Hombre)': 'de-Spk0_man',
    'Alemán (Mujer)': 'de-Spk1_woman',
    'Francés (Hombre)': 'fr-Spk0_man',
    'Francés (Mujer)': 'fr-Spk1_woman',
  };

  /// Parámetros por defecto
  static const double defaultCfgScale = 1.5; // 1.0-3.0 (recomendado: 1.5)
  static const int defaultInferenceSteps = 5; // 1-20 (recomendado: 5)
  static const String defaultVoice = 'Carter';
}

/// ============================================================================
/// MODELO DE DATOS - Para manejar la generación de audio
/// ============================================================================

class VibeVoiceGenerationState {
  final bool isGenerating;
  final bool isConnected;
  final int chunksReceived;
  final int totalBytes;
  final String? error;
  final double? progress; // 0.0 a 1.0

  VibeVoiceGenerationState({
    this.isGenerating = false,
    this.isConnected = false,
    this.chunksReceived = 0,
    this.totalBytes = 0,
    this.error,
    this.progress,
  });

  // Copiar con cambios (como copyWith en Dart)
  VibeVoiceGenerationState copyWith({
    bool? isGenerating,
    bool? isConnected,
    int? chunksReceived,
    int? totalBytes,
    String? error,
    double? progress,
  }) {
    return VibeVoiceGenerationState(
      isGenerating: isGenerating ?? this.isGenerating,
      isConnected: isConnected ?? this.isConnected,
      chunksReceived: chunksReceived ?? this.chunksReceived,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error ?? this.error,
      progress: progress ?? this.progress,
    );
  }

  @override
  String toString() {
    return '''VibeVoiceGenerationState(
      isGenerating: $isGenerating,
      isConnected: $isConnected,
      chunksReceived: $chunksReceived,
      totalBytes: $totalBytes,
      error: $error,
      progress: $progress,
    )''';
  }
}

/// ============================================================================
/// SERVICIO PRINCIPAL - VibeVoiceTTSService
/// ============================================================================
///
/// Este es el servicio que controla todo.
/// Lo usarías así en tu UI:
///
/// ```dart
/// final ttsService = VibeVoiceTTSService();
///
/// // En initState():
/// ttsService.init();
///
/// // Para generar audio:
/// ttsService.generateSpeech(
///   text: 'Hola mundo',
///   voiceName: 'Carter',
/// );
///
/// // Escuchar cambios de estado:
/// ttsService.stateStream.listen((state) {
///   print('Chunks: ${state.chunksReceived}');
/// });
/// ```

class VibeVoiceTTSService {
  /// Stream de estado (como notifyListeners en Provider)
  final _stateController =
      StreamController<VibeVoiceGenerationState>.broadcast();
  Stream<VibeVoiceGenerationState> get stateStream => _stateController.stream;

  /// Stream de chunks de audio (para reproducir)
  final _audioController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get audioStream => _audioController.stream;

  // Estado actual
  VibeVoiceGenerationState _currentState = VibeVoiceGenerationState();

  // Conexión WebSocket
  WebSocketChannel? _channel;

  // Para cancelar operaciones
  StreamSubscription? _streamSubscription;

  /// Inicializar el servicio
  Future<void> init() async {
    print('🎤 VibeVoiceTTSService inicializado');
  }

  /// FUNCIÓN PRINCIPAL: Generar audio en tiempo real
  ///
  /// Equivalente en Flutter a:
  /// ```dart
  /// FutureBuilder<void>(
  ///   future: ttsService.generateSpeech(...),
  ///   builder: (context, snapshot) { ... }
  /// )
  /// ```
  Future<void> generateSpeech({
    required String text,
    String voiceName = VibeVoiceConfig.defaultVoice,
    double cfgScale = VibeVoiceConfig.defaultCfgScale,
    int inferenceSteps = VibeVoiceConfig.defaultInferenceSteps,
  }) async {
    try {
      // Validar entrada
      if (text.trim().isEmpty) {
        _updateState(
          _currentState.copyWith(error: 'El texto no puede estar vacío'),
        );
        return;
      }

      // Obtener la voz real del servidor
      final voiceKey =
          VibeVoiceConfig.voces[voiceName] ?? VibeVoiceConfig.voces['Carter']!;

      // Actualizar estado: iniciando
      _updateState(
        _currentState.copyWith(
          isGenerating: true,
          isConnected: false,
          chunksReceived: 0,
          totalBytes: 0,
          error: null,
          progress: 0.0,
        ),
      );

      // Construir URL WebSocket con parámetros
      final wsUrl = Uri.parse(
        '${VibeVoiceConfig.baseUrl}/stream'
        '?text=${Uri.encodeComponent(text)}'
        '&voice=$voiceKey'
        '&cfg=$cfgScale'
        '&steps=$inferenceSteps',
      );

      print('📡 Conectando a: $wsUrl');

      // Conectar al servidor (equivalente a WebSocket.connect)
      _channel = WebSocketChannel.connect(wsUrl);

      // Actualizar estado: conectado
      _updateState(_currentState.copyWith(isConnected: true));
      print('✓ Conectado al servidor WebSocket');

      // Escuchar el stream de audio
      int chunksReceived = 0;
      int totalBytes = 0;

      _streamSubscription = _channel!.stream.listen(
        (dynamic data) {
          // Cada mensaje es un chunk de audio (Uint8List)
          final audioChunk = data is Uint8List
              ? data
              : Uint8List.fromList(data);

          chunksReceived++;
          totalBytes += audioChunk.length;

          // Emitir el chunk para que el reproductor lo use
          _audioController.add(audioChunk);

          // Actualizar estado
          _updateState(
            _currentState.copyWith(
              chunksReceived: chunksReceived,
              totalBytes: totalBytes,
              progress: (chunksReceived / 100).clamp(0.0, 0.95), // Simulado
            ),
          );

          print('📦 Chunk $chunksReceived: ${audioChunk.length} bytes');
        },
        onError: (error) {
          print('❌ Error en stream: $error');
          _updateState(
            _currentState.copyWith(
              error: error.toString(),
              isGenerating: false,
            ),
          );
        },
        onDone: () {
          print('✅ Stream completado');
          _updateState(
            _currentState.copyWith(
              isGenerating: false,
              isConnected: false,
              progress: 1.0,
            ),
          );
        },
      );
    } catch (e) {
      print('❌ Error: $e');
      _updateState(
        _currentState.copyWith(error: e.toString(), isGenerating: false),
      );
    }
  }

  /// Cancelar la generación actual
  void cancelGeneration() {
    print('⏹️ Cancelando generación...');
    _streamSubscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _updateState(
      _currentState.copyWith(isGenerating: false, isConnected: false),
    );
  }

  /// Actualizar estado (notificar a listeners)
  void _updateState(VibeVoiceGenerationState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  /// Limpiar recursos
  void dispose() {
    print('🗑️ Limpiando VibeVoiceTTSService...');
    _streamSubscription?.cancel();
    _channel?.sink.close();
    _stateController.close();
    _audioController.close();
  }
}

/// ============================================================================
/// UI WIDGETS - Componentes para tu interfaz
/// ============================================================================

// Esto es un EJEMPLO de cómo usarías esto en una pantalla

/*
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class VibeVoiceDemoScreen extends StatefulWidget {
  @override
  State<VibeVoiceDemoScreen> createState() => _VibeVoiceDemoScreenState();
}

class _VibeVoiceDemoScreenState extends State<VibeVoiceDemoScreen> {
  late final VibeVoiceTTSService ttsService;
  late final AudioPlayer audioPlayer;
  final textController = TextEditingController();
  String selectedVoice = VibeVoiceConfig.defaultVoice;

  @override
  void initState() {
    super.initState();
    
    // Inicializar servicios
    ttsService = VibeVoiceTTSService();
    audioPlayer = AudioPlayer();
    ttsService.init();

    // Escuchar chunks de audio y reproducirlos
    ttsService.audioStream.listen((audioChunk) {
      // Aquí reproducirías el audio
      // audioPlayer.play(audioChunk);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🎙️ VibeVoice TTS')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Campo de texto
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Escribe el texto a convertir a voz...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),

            // Selector de voz (Dropdown como en Flutter)
            DropdownButton<String>(
              value: selectedVoice,
              items: VibeVoiceConfig.voces.keys
                  .map((voice) => DropdownMenuItem(
                        value: voice,
                        child: Text(voice),
                      ))
                  .toList(),
              onChanged: (voice) {
                setState(() => selectedVoice = voice!);
              },
            ),
            SizedBox(height: 16),

            // Botón de generar (StreamBuilder para estado)
            StreamBuilder<VibeVoiceGenerationState>(
              stream: ttsService.stateStream,
              initialData: VibeVoiceGenerationState(),
              builder: (context, snapshot) {
                final state = snapshot.data!;
                final isGenerating = state.isGenerating;

                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: isGenerating
                          ? () => ttsService.cancelGeneration()
                          : () => ttsService.generateSpeech(
                                text: textController.text,
                                voiceName: selectedVoice,
                              ),
                      child: Text(
                        isGenerating ? '⏹️ Cancelar' : '▶️ Generar Audio',
                      ),
                    ),
                    if (isGenerating) ...[
                      SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: state.progress,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Chunks: ${state.chunksReceived} | ${(state.totalBytes / 1024).toStringAsFixed(1)} KB',
                      ),
                    ],
                    if (state.error != null) ...[
                      SizedBox(height: 16),
                      Text(
                        'Error: ${state.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    textController.dispose();
    audioPlayer.dispose();
    ttsService.dispose();
    super.dispose();
  }
}
*/

/// ============================================================================
/// EJEMPLO DE USO SIMPLE
/// ============================================================================

void main() async {
  // En una app Flutter real, esto estaría en main.dart
  final ttsService = VibeVoiceTTSService();
  await ttsService.init();

  // Generar audio
  await ttsService.generateSpeech(
    text: 'Hola, este es un ejemplo de síntesis de voz en tiempo real',
    voiceName: 'Carter',
    cfgScale: 1.5,
    inferenceSteps: 5,
  );

  // Escuchar estado
  ttsService.stateStream.listen((state) {
    print('Estado: $state');
  });

  // Escuchar audio
  ttsService.audioStream.listen((audioChunk) {
    print('Audio chunk recibido: ${audioChunk.length} bytes');
    // Aquí reproducirías con AudioPlayer
  });
}
