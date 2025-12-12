/// PANTALLA FLUTTER COMPLETA - VibeVoice TTS Demo
///
/// Este archivo es un ejemplo COMPLETO de cómo integrar VibeVoice en tu app Flutter.
/// Solo cópialo a tu proyecto y ajusta los imports.

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:async';
import 'dart:typed_data';

/// ============================================================================
/// CONFIGURACIÓN Y SERVICIO (igual al archivo anterior)
/// ============================================================================

class VibeVoiceConfig {
  static const String baseUrl = 'ws://localhost:3000';

  static const Map<String, String> voces = {
    'Carter (Hombre)': 'en-Carter_man',
    'Emma (Mujer)': 'en-Emma_woman',
    'Frank (Hombre)': 'en-Frank_man',
    'Grace (Mujer)': 'en-Grace_woman',
    'Mike (Hombre)': 'en-Mike_man',
    'Davis (Hombre)': 'en-Davis_man',
    'Alemán (Hombre)': 'de-Spk0_man',
    'Alemán (Mujer)': 'de-Spk1_woman',
    'Francés (Hombre)': 'fr-Spk0_man',
    'Francés (Mujer)': 'fr-Spk1_woman',
  };

  static const double defaultCfgScale = 1.5;
  static const int defaultInferenceSteps = 5;
  static const String defaultVoice = 'Carter (Hombre)';
}

class VibeVoiceGenerationState {
  final bool isGenerating;
  final bool isConnected;
  final int chunksReceived;
  final int totalBytes;
  final String? error;
  final double progress;

  VibeVoiceGenerationState({
    this.isGenerating = false,
    this.isConnected = false,
    this.chunksReceived = 0,
    this.totalBytes = 0,
    this.error,
    this.progress = 0.0,
  });

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
}

class VibeVoiceTTSService {
  final _stateController =
      StreamController<VibeVoiceGenerationState>.broadcast();
  Stream<VibeVoiceGenerationState> get stateStream => _stateController.stream;

  final _audioController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get audioStream => _audioController.stream;

  VibeVoiceGenerationState _currentState = VibeVoiceGenerationState();
  WebSocketChannel? _channel;
  StreamSubscription? _streamSubscription;

  Future<void> init() async {
    // Inicialización si es necesaria
  }

  Future<void> generateSpeech({
    required String text,
    String voiceName = VibeVoiceConfig.defaultVoice,
    double cfgScale = VibeVoiceConfig.defaultCfgScale,
    int inferenceSteps = VibeVoiceConfig.defaultInferenceSteps,
  }) async {
    try {
      if (text.trim().isEmpty) {
        _updateState(
          _currentState.copyWith(error: 'El texto no puede estar vacío'),
        );
        return;
      }

      final voiceKey =
          VibeVoiceConfig.voces[voiceName] ??
          VibeVoiceConfig.voces[VibeVoiceConfig.defaultVoice]!;

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

      final wsUrl = Uri.parse(
        '${VibeVoiceConfig.baseUrl}/stream'
        '?text=${Uri.encodeComponent(text)}'
        '&voice=$voiceKey'
        '&cfg=$cfgScale'
        '&steps=$inferenceSteps',
      );

      _channel = WebSocketChannel.connect(wsUrl);
      _updateState(_currentState.copyWith(isConnected: true));

      int chunksReceived = 0;
      int totalBytes = 0;

      _streamSubscription = _channel!.stream.listen(
        (dynamic data) {
          final audioChunk = data is Uint8List
              ? data
              : Uint8List.fromList(data);

          chunksReceived++;
          totalBytes += audioChunk.length;

          _audioController.add(audioChunk);

          _updateState(
            _currentState.copyWith(
              chunksReceived: chunksReceived,
              totalBytes: totalBytes,
            ),
          );
        },
        onError: (error) {
          _updateState(
            _currentState.copyWith(
              error: error.toString(),
              isGenerating: false,
            ),
          );
        },
        onDone: () {
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
      _updateState(
        _currentState.copyWith(error: e.toString(), isGenerating: false),
      );
    }
  }

  void cancelGeneration() {
    _streamSubscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _updateState(
      _currentState.copyWith(isGenerating: false, isConnected: false),
    );
  }

  void _updateState(VibeVoiceGenerationState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _streamSubscription?.cancel();
    _channel?.sink.close();
    _stateController.close();
    _audioController.close();
  }
}

/// ============================================================================
/// PANTALLA FLUTTER - Lista para usar
/// ============================================================================

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeVoice TTS',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const VibeVoiceDemoScreen(),
    );
  }
}

class VibeVoiceDemoScreen extends StatefulWidget {
  const VibeVoiceDemoScreen({Key? key}) : super(key: key);

  @override
  State<VibeVoiceDemoScreen> createState() => _VibeVoiceDemoScreenState();
}

class _VibeVoiceDemoScreenState extends State<VibeVoiceDemoScreen> {
  late final VibeVoiceTTSService ttsService;
  final textController = TextEditingController();
  String selectedVoice = VibeVoiceConfig.defaultVoice;
  double cfgScale = VibeVoiceConfig.defaultCfgScale;
  int inferenceSteps = VibeVoiceConfig.defaultInferenceSteps;

  @override
  void initState() {
    super.initState();
    ttsService = VibeVoiceTTSService();
    ttsService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎙️ VibeVoice TTS Demo'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. CAMPO DE TEXTO
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Texto a convertir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: 'Escribe el texto aquí...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.edit),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. SELECTOR DE VOZ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seleccionar voz',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedVoice,
                      isExpanded: true,
                      items: VibeVoiceConfig.voces.keys
                          .map(
                            (voice) => DropdownMenuItem(
                              value: voice,
                              child: Text(voice),
                            ),
                          )
                          .toList(),
                      onChanged: (voice) {
                        setState(() => selectedVoice = voice!);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. CONTROLES AVANZADOS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuración avanzada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // CFG Scale
                    Text('CFG Scale: ${cfgScale.toStringAsFixed(2)}'),
                    Slider(
                      value: cfgScale,
                      min: 1.0,
                      max: 3.0,
                      divisions: 20,
                      onChanged: (value) {
                        setState(() => cfgScale = value);
                      },
                    ),
                    const Text(
                      '1.5 = recomendado (más fidelidad al texto)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // Inference Steps
                    Text('Pasos de inferencia: $inferenceSteps'),
                    Slider(
                      value: inferenceSteps.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      onChanged: (value) {
                        setState(() => inferenceSteps = value.toInt());
                      },
                    ),
                    const Text(
                      '5 = rápido, 20 = alta calidad',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. BOTÓN Y ESTADO (StreamBuilder)
            StreamBuilder<VibeVoiceGenerationState>(
              stream: ttsService.stateStream,
              initialData: VibeVoiceGenerationState(),
              builder: (context, snapshot) {
                final state = snapshot.data!;
                final isGenerating = state.isGenerating;

                return Column(
                  children: [
                    // BOTÓN PRINCIPAL
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isGenerating
                            ? () => ttsService.cancelGeneration()
                            : () => ttsService.generateSpeech(
                                text: textController.text,
                                voiceName: selectedVoice,
                                cfgScale: cfgScale,
                                inferenceSteps: inferenceSteps,
                              ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: isGenerating
                              ? Colors.red
                              : Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isGenerating ? '⏹️ Cancelar' : '▶️ Generar Audio',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ESTADO
                    if (state.isConnected) ...[
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📡 Conectado al servidor',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Barra de progreso
                              LinearProgressIndicator(
                                value: state.progress > 0
                                    ? state.progress
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // Estadísticas
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Chunks: ${state.chunksReceived}'),
                                  Text(
                                    'Tamaño: ${(state.totalBytes / 1024).toStringAsFixed(1)} KB',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ERROR
                    if (state.error != null) ...[
                      Card(
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '❌ Error',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(state.error!),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // COMPLETADO
                    if (state.progress == 1.0 && !state.isGenerating) ...[
                      Card(
                        color: Colors.green[50],
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✅ Audio generado correctamente',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'El audio se ha generado en tiempo real. '
                                'En una app real, estaría reproduciéndose ahora mismo.',
                              ),
                            ],
                          ),
                        ),
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
    ttsService.dispose();
    super.dispose();
  }
}
