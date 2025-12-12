## 📚 REFERENCIA RÁPIDA - VibeVoice para Flutter

### 🎯 Copy & Paste básico

```dart
import 'vibevoice_flutter_client.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final VibeVoiceTTSService tts;

  @override
  void initState() {
    super.initState();
    tts = VibeVoiceTTSService();
    tts.init();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(onChanged: (text) {}),
        ElevatedButton(
          onPressed: () => tts.generateSpeech(
            text: 'Hola mundo',
            voiceName: 'Carter (Hombre)',
          ),
          child: Text('▶️ Generar Audio'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    tts.dispose();
    super.dispose();
  }
}
```

### 📡 Conectarse y escuchar estado

```dart
// Generar audio
tts.generateSpeech(
  text: 'Tu texto',
  voiceName: 'Carter (Hombre)',
  cfgScale: 1.5,              // Fidelidad al texto
  inferenceSteps: 5,          // Calidad
);

// Escuchar cambios
tts.stateStream.listen((state) {
  print('Generando: ${state.isGenerating}');
  print('Chunks: ${state.chunksReceived}');
  print('Bytes: ${state.totalBytes}');
  if (state.error != null) print('Error: ${state.error}');
});

// Recibir chunks de audio
tts.audioStream.listen((audioChunk) {
  // audioChunk es Uint8List
  // Reproducir con audioPlayer.play(audioChunk)
});

// Cancelar
tts.cancelGeneration();
```

### 🎤 Voces disponibles

```
En inglés:
✓ Carter (Hombre)
✓ Emma (Mujer)
✓ Frank (Hombre)
✓ Grace (Mujer)
✓ Mike (Hombre)
✓ Davis (Hombre)

En otros idiomas:
✓ Alemán (Hombre/Mujer)
✓ Francés (Hombre/Mujer)
✓ Italiano (Hombre/Mujer)
✓ Japonés (Hombre/Mujer)
✓ Coreano (Hombre/Mujer)
✓ Holandés (Hombre/Mujer)
✓ Polaco (Hombre/Mujer)
✓ Portugués (Hombre/Mujer)
✓ Español (Hombre/Mujer)
```

### 📊 Parámetros

| Parámetro | Rango | Recomendado | Efecto |
|-----------|-------|-------------|--------|
| `cfgScale` | 1.0-3.0 | **1.5** | Cuánto sigue al texto |
| `inferenceSteps` | 1-20 | **5** | Calidad vs velocidad |

### 🎨 StreamBuilder para UI

```dart
StreamBuilder<VibeVoiceGenerationState>(
  stream: tts.stateStream,
  initialData: VibeVoiceGenerationState(),
  builder: (context, snapshot) {
    final state = snapshot.data!;
    
    return Column(
      children: [
        if (state.isGenerating)
          LinearProgressIndicator(value: state.progress),
        Text('Chunks: ${state.chunksReceived}'),
        if (state.error != null)
          Text('Error: ${state.error}', style: TextStyle(color: Colors.red)),
      ],
    );
  },
)
```

### 🔴 Estados posibles

```dart
class VibeVoiceGenerationState {
  bool isGenerating;      // true mientras genera
  bool isConnected;       // true si WebSocket conectado
  int chunksReceived;     // 0, 1, 2, 3, ...
  int totalBytes;         // bytes acumulados
  String? error;          // null si no hay error
  double progress;        // 0.0 a 1.0
}
```

### ⚠️ Errores comunes

| Error | Causa | Solución |
|-------|-------|----------|
| `Connection refused` | Servidor no corre | `python demo/vibevoice_realtime_demo.py` |
| `TextField null` | No inicializado | `await tts.init()` antes de usar |
| `Audio cortado` | Buffer pequeño | Acumular más chunks antes de reproducir |
| `WebSocket no conecta` | URL incorrecta | Verificar `VibeVoiceConfig.baseUrl` |

### 🧹 Limpiar recursos

```dart
@override
void dispose() {
  tts.dispose();  // IMPORTANTE: liberar WebSocket
  super.dispose();
}
```

### 📱 Reproducir audio (con just_audio)

```yaml
dependencies:
  just_audio: ^0.9.36
```

```dart
import 'package:just_audio/just_audio.dart';

final audioPlayer = AudioPlayer();

tts.audioStream.listen((audioChunk) {
  // Convertir a WAV y reproducir
  // (implementación específica de just_audio)
  audioPlayer.setAudioSource(
    AudioSource.file('path_to_audio'),
  );
  audioPlayer.play();
});
```

### 🚀 Iniciar servidor VibeVoice

```bash
# Terminal 1: Servidor
python demo/vibevoice_realtime_demo.py \
  --model_path microsoft/VibeVoice-Realtime-0.5B \
  --port 3000 \
  --device mps

# Terminal 2: Tu app Flutter
flutter run
```

### 📦 Estructura de proyecto recomendada

```
lib/
├── main.dart
├── services/
│   └── vibevoice_service.dart      ← Copiar vibevoice_flutter_client.dart
├── screens/
│   └── vibevoice_screen.dart       ← Copiar flutter_demo_screen.dart
├── models/
│   └── vibevoice_models.dart       ← Estados y configuración
└── widgets/
    └── audio_player.dart           ← Componentes reutilizables
```

### 🎓 Vocabulario Flutter → VibeVoice

| Concepto Flutter | En VibeVoice |
|------------------|--------------|
| `StreamBuilder` | Escucha `stateStream` o `audioStream` |
| `FutureBuilder` | Llama `generateSpeech()` |
| `setState` | `stateStream` emite nuevos estados |
| `ChangeNotifier` | `VibeVoiceTTSService` con streams |
| `Provider` | Puedes envolver `VibeVoiceTTSService` |
| `WebSocket` | Manejado internamente |
| `Uint8List` | Chunks de audio en `audioStream` |

### 💡 Tips

1. **Usar Streams para todo**: No uses `setState` directamente con estado del servicio
2. **Limpiar siempre**: Llama a `dispose()` cuando termines
3. **Buffer de audio**: Acumula chunks antes de reproducir para mejor experiencia
4. **CFG Scale**: Empieza con 1.5, ajusta según necesites más fidelidad al texto
5. **Inference Steps**: 5 es perfecto para realtime, aumenta si necesitas más calidad

### 🔗 Referencias

- Servicio completo: `vibevoice_flutter_client.dart`
- Demo funcional: `flutter_demo_screen.dart`
- Ejemplos avanzados: `flutter_advanced_examples.dart`
- Documentación: `FLUTTER_README.md`

---

**Generado para desarrolladores Flutter que integran VibeVoice en tiempo real. ¡Haz que tu app hable! 🎤**
