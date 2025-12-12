# 🎙️ Cliente Flutter para VibeVoice

Este directorio contiene clientes listos para usar VibeVoice en tu app Flutter.

## 📁 Archivos incluidos

1. **`vibevoice_flutter_client.dart`** - Servicio reutilizable para cualquier app
2. **`flutter_demo_screen.dart`** - Pantalla completa lista para usar
3. **`flutter_client_example.dart`** - Ejemplos y explicaciones en términos Flutter

## 🚀 Instalación rápida

### 1. Añadir dependencias a `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  web_socket_channel: ^2.4.0
```

### 2. Copiar el servicio a tu proyecto

```
your_flutter_app/
├── lib/
│   ├── main.dart
│   ├── services/
│   │   └── vibevoice_service.dart  ← Copiar aquí
│   └── screens/
│       └── vibevoice_screen.dart   ← O copiar aquí
```

### 3. Usar en tu app

**Opción A: Usar la pantalla completa**
```dart
import 'flutter_demo_screen.dart';

void main() {
  runApp(const MyApp());
}
```

**Opción B: Integrar el servicio en tu app**
```dart
import 'services/vibevoice_service.dart';

class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late final VibeVoiceTTSService ttsService;

  @override
  void initState() {
    super.initState();
    ttsService = VibeVoiceTTSService();
    ttsService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: (text) {
            // Hacer algo con el texto
          },
        ),
        ElevatedButton(
          onPressed: () => ttsService.generateSpeech(
            text: 'Hola mundo',
            voiceName: 'Carter (Hombre)',
          ),
          child: Text('Generar Audio'),
        ),
        StreamBuilder<VibeVoiceGenerationState>(
          stream: ttsService.stateStream,
          builder: (context, snapshot) {
            final state = snapshot.data ?? VibeVoiceGenerationState();
            if (state.isGenerating) {
              return LinearProgressIndicator();
            }
            return SizedBox.shrink();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    ttsService.dispose();
    super.dispose();
  }
}
```

## 📖 Conceptos principales (en términos Flutter)

### 1. VibeVoiceTTSService
Es como un **Service Provider** o **ChangeNotifier**.

```dart
// Crear una instancia
final service = VibeVoiceTTSService();

// Inicializar
await service.init();

// Generar audio (como hacer una petición HTTP)
await service.generateSpeech(
  text: 'Texto a convertir',
  voiceName: 'Carter (Hombre)',
);

// Escuchar cambios de estado (como StreamBuilder)
service.stateStream.listen((state) {
  print('Estado: ${state.isGenerating}');
  print('Chunks recibidos: ${state.chunksReceived}');
});

// Escuchar chunks de audio (como un Stream de datos)
service.audioStream.listen((audioChunk) {
  // audioChunk es Uint8List
  // Reproducir con AudioPlayer
});

// Cancelar
service.cancelGeneration();

// Limpiar
service.dispose();
```

### 2. VibeVoiceGenerationState
Es el modelo de datos que contiene el estado actual.

```dart
class VibeVoiceGenerationState {
  bool isGenerating;      // ¿Se está generando?
  bool isConnected;       // ¿WebSocket conectado?
  int chunksReceived;     // Número de chunks recibidos
  int totalBytes;         // Bytes totales recibidos
  String? error;          // Mensaje de error (si hay)
  double progress;        // Progreso 0.0-1.0
}
```

### 3. Flujo de datos (como un Stream)

```
Usuario escribe texto
    ↓
ttsService.generateSpeech()
    ↓
WebSocket se conecta al servidor
    ↓
Servidor genera audio y emite chunks
    ↓
audioStream.listen() recibe cada chunk
    ↓
AudioPlayer reproduce en tiempo real
```

## 🎤 Voces disponibles

```dart
VibeVoiceConfig.voces
// {
//   'Carter (Hombre)': 'en-Carter_man',
//   'Emma (Mujer)': 'en-Emma_woman',
//   'Frank (Hombre)': 'en-Frank_man',
//   'Grace (Mujer)': 'en-Grace_woman',
//   'Mike (Hombre)': 'en-Mike_man',
//   'Davis (Hombre)': 'en-Davis_man',
//   'Alemán (Hombre)': 'de-Spk0_man',
//   'Alemán (Mujer)': 'de-Spk1_woman',
//   'Francés (Hombre)': 'fr-Spk0_man',
//   'Francés (Mujer)': 'fr-Spk1_woman',
// }
```

## ⚙️ Parámetros de configuración

```dart
await ttsService.generateSpeech(
  text: 'Texto a convertir',
  voiceName: 'Carter (Hombre)',              // Voz a usar
  cfgScale: 1.5,                             // 1.0-3.0 (recomendado: 1.5)
  inferenceSteps: 5,                         // 1-20 (recomendado: 5)
);
```

- **cfgScale**: Controla cuánto sigue el audio al texto
  - 1.0 = Sin seguimiento (audio genérico)
  - 1.5 = Balance perfecto ⭐ (RECOMENDADO)
  - 3.0 = Sigue mucho el texto (menos natural)

- **inferenceSteps**: Calidad vs velocidad
  - 5 = Muy rápido, buena calidad ⭐ (RECOMENDADO)
  - 10 = Mejor calidad, más lento
  - 20 = Máxima calidad, muy lento

## 📱 Reproducir audio con just_audio

Para reproducir el audio en tiempo real, añade `just_audio`:

```yaml
dependencies:
  just_audio: ^0.9.36
```

```dart
import 'package:just_audio/just_audio.dart';

class _MyPageState extends State<MyPage> {
  late final AudioPlayer audioPlayer;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();

    // Reproducir chunks conforme llegan
    ttsService.audioStream.listen((audioChunk) {
      // Aquí reproducirías el audio
      // (implementación depende de how_audio maneja streams)
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}
```

## 🔧 Solución de problemas

### "Error: Connection refused"
- Asegúrate de que el servidor VibeVoice esté corriendo:
  ```bash
  python demo/vibevoice_realtime_demo.py --model_path microsoft/VibeVoice-Realtime-0.5B
  ```

### "Error: No module named 'transformers'"
- Instala las dependencias del servidor:
  ```bash
  pip install -e .
  ```

### El audio se corta o no se reproduce
- Verificar que `just_audio` esté configurado correctamente
- En iOS, necesitas permisos en `Info.plist`:
  ```xml
  <key>NSMicrophoneUsageDescription</key>
  <string>Necesitamos acceso al micrófono</string>
  ```

## 📊 Ejemplo: Mostrar progreso

```dart
StreamBuilder<VibeVoiceGenerationState>(
  stream: ttsService.stateStream,
  builder: (context, snapshot) {
    final state = snapshot.data ?? VibeVoiceGenerationState();
    
    return Column(
      children: [
        if (state.isGenerating) ...[
          LinearProgressIndicator(value: state.progress),
          Text('${state.chunksReceived} chunks | ${(state.totalBytes/1024).toStringAsFixed(1)} KB'),
        ],
        if (state.error != null) ...[
          Text('Error: ${state.error}', style: TextStyle(color: Colors.red)),
        ],
      ],
    );
  },
)
```

## 🎓 Conceptos clave para ti (desarrollador Flutter)

| Concepto | Equivalente en este código |
|----------|---------------------------|
| `StatelessWidget` | No aplica (servicio sin estado visual) |
| `StatefulWidget` | Tu pantalla que usa el servicio |
| `StreamBuilder` | Para escuchar `stateStream` y `audioStream` |
| `FutureBuilder` | Para `generateSpeech()` |
| `ChangeNotifier` | `VibeVoiceTTSService` con `stateStream` |
| `Provider` | Podrías envolver el servicio con Provider |
| `WebSocket` | Manejado internamente por el servicio |
| `Stream` | `stateStream` y `audioStream` |

## 💡 Próximas características

- [ ] Provider integration (para gestión de estado avanzada)
- [ ] Caché de voces (descargar una sola vez)
- [ ] Reproducción automática con just_audio
- [ ] Gestos de control (pausar, reanudar)
- [ ] Historial de generaciones

## 📞 Soporte

Si tienes problemas:
1. Verifica que el servidor esté corriendo
2. Revisa los logs en la terminal del servidor
3. Consulta [vibevoice-realtime-0.5b.md](../docs/vibevoice-realtime-0.5b.md)

---

**Creado para desarrolladores Flutter que quieren usar VibeVoice TTS en tiempo real.**
