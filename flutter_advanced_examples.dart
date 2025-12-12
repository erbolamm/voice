/// EJEMPLOS AVANZADOS - Patrones de uso común en Flutter

import 'package:flutter/material.dart';
import 'vibevoice_flutter_client.dart';

/// ============================================================================
/// EJEMPLO 1: Usar con Provider (gestión de estado recomendada)
/// ============================================================================

/*
import 'package:provider/provider.dart';

class VibeVoiceProvider with ChangeNotifier {
  final VibeVoiceTTSService _service = VibeVoiceTTSService();
  
  VibeVoiceGenerationState get state => _service._currentState;
  Stream<VibeVoiceGenerationState> get stateStream => _service.stateStream;
  Stream<Uint8List> get audioStream => _service.audioStream;

  Future<void> generateSpeech({
    required String text,
    required String voice,
  }) async {
    await _service.generateSpeech(text: text, voiceName: voice);
  }

  void cancel() => _service.cancelGeneration();

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

// En main.dart:
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VibeVoiceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// En tu pantalla:
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<VibeVoiceProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            ElevatedButton(
              onPressed: () => provider.generateSpeech(
                text: 'Hola',
                voice: 'Carter (Hombre)',
              ),
              child: Text('Generar'),
            ),
          ],
        );
      },
    );
  }
}
*/

/// ============================================================================
/// EJEMPLO 2: Reproducir audio automáticamente con just_audio
/// ============================================================================

/*
import 'package:just_audio/just_audio.dart';
import 'dart:typed_data';

class VibeVoiceWithAudioPlayer extends StatefulWidget {
  @override
  State<VibeVoiceWithAudioPlayer> createState() => _VibeVoiceWithAudioPlayerState();
}

class _VibeVoiceWithAudioPlayerState extends State<VibeVoiceWithAudioPlayer> {
  late final VibeVoiceTTSService ttsService;
  late final AudioPlayer audioPlayer;
  final audioBuffer = <int>[];
  bool isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    ttsService = VibeVoiceTTSService();
    audioPlayer = AudioPlayer();
    ttsService.init();

    // Acumular chunks y reproducir
    ttsService.audioStream.listen((audioChunk) {
      audioBuffer.addAll(audioChunk);
      
      // Reproducir cuando tengamos suficientes datos
      if (!isPlayingAudio && audioBuffer.length > 48000) {
        _playAccumulatedAudio();
      }
    });
  }

  Future<void> _playAccumulatedAudio() async {
    isPlayingAudio = true;
    final audioData = Uint8List.fromList(audioBuffer);
    // Reproducir con just_audio
    // audioPlayer.play(...)
  }

  @override
  void dispose() {
    ttsService.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => ttsService.generateSpeech(
        text: 'Hola mundo con reproducción automática',
        voiceName: 'Carter (Hombre)',
      ),
      child: Text('Generar y reproducir'),
    );
  }
}
*/

/// ============================================================================
/// EJEMPLO 3: Mostrar progreso detallado en tiempo real
/// ============================================================================

class VibeVoiceProgressScreen extends StatefulWidget {
  const VibeVoiceProgressScreen({Key? key}) : super(key: key);

  @override
  State<VibeVoiceProgressScreen> createState() =>
      _VibeVoiceProgressScreenState();
}

class _VibeVoiceProgressScreenState extends State<VibeVoiceProgressScreen> {
  late final VibeVoiceTTSService ttsService;
  final textController = TextEditingController();
  final stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    ttsService = VibeVoiceTTSService();
    ttsService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso en Tiempo Real')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Escribe el texto...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                stopwatch.restart();
                ttsService.generateSpeech(
                  text: textController.text,
                  voiceName: 'Carter (Hombre)',
                );
              },
              child: const Text('Generar'),
            ),
            const SizedBox(height: 24),
            // Mostrar progreso detallado
            Expanded(
              child: StreamBuilder<VibeVoiceGenerationState>(
                stream: ttsService.stateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data ?? VibeVoiceGenerationState();

                  if (!state.isGenerating && !state.isConnected) {
                    return const Center(
                      child: Text('Escribe y presiona "Generar"'),
                    );
                  }

                  final elapsed = stopwatch.elapsed;
                  final seconds = elapsed.inSeconds;
                  final milliseconds = elapsed.inMilliseconds % 1000;
                  final estimatedTotal = state.totalBytes > 0
                      ? (state.totalBytes / (state.totalBytes / seconds))
                            .toStringAsFixed(1)
                      : '...';

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Estado general
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estado actual',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.isGenerating
                                      ? '🟢 Generando...'
                                      : '🔴 Completado',
                                  style: TextStyle(
                                    color: state.isGenerating
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Progreso
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Progreso de descarga',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: state.progress > 0
                                        ? state.progress
                                        : null,
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(state.progress * 100).toStringAsFixed(1)}%',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Estadísticas en tiempo real
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estadísticas',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                _StatRow(
                                  label: 'Chunks recibidos',
                                  value: '${state.chunksReceived}',
                                ),
                                _StatRow(
                                  label: 'Datos recibidos',
                                  value:
                                      '${(state.totalBytes / 1024).toStringAsFixed(1)} KB',
                                ),
                                _StatRow(
                                  label: 'Tiempo transcurrido',
                                  value:
                                      '$seconds.${milliseconds.toString().padLeft(3, '0')}s',
                                ),
                                if (seconds > 0)
                                  _StatRow(
                                    label: 'Velocidad',
                                    value:
                                        '${(state.totalBytes / seconds / 1024).toStringAsFixed(1)} KB/s',
                                  ),
                                if (estimatedTotal != '...')
                                  _StatRow(
                                    label: 'Tiempo estimado total',
                                    value: '${estimatedTotal}s',
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Mostrar error si hay
                        if (state.error != null) ...[
                          const SizedBox(height: 16),
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
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(state.error!),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
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
    stopwatch.stop();
    super.dispose();
  }
}

/// Widget auxiliar para mostrar estadísticas
class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// EJEMPLO 4: Chat con VibeVoice (convertir respuestas a voz)
/// ============================================================================

/*
class ChatWithVibeVoice extends StatefulWidget {
  @override
  State<ChatWithVibeVoice> createState() => _ChatWithVibeVoiceState();
}

class _ChatWithVibeVoiceState extends State<ChatWithVibeVoice> {
  late final VibeVoiceTTSService ttsService;
  final messages = <String>[];
  final messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ttsService = VibeVoiceTTSService();
    ttsService.init();
  }

  void _sendMessage(String text) {
    setState(() => messages.add('Usuario: $text'));
    messageController.clear();

    // Simular respuesta del servidor
    final response = 'Respuesta a: $text';
    setState(() => messages.add('Bot: $response'));

    // Convertir respuesta a voz automáticamente
    ttsService.generateSpeech(
      text: response,
      voiceName: 'Carter (Hombre)',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg.startsWith('Usuario');
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      msg.replaceFirst(isUser ? 'Usuario: ' : 'Bot: ', ''),
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _sendMessage(messageController.text),
                  child: const Text('Enviar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    ttsService.dispose();
    super.dispose();
  }
}
*/

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeVoice Ejemplos',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const VibeVoiceProgressScreen(),
    );
  }
}
