# 📚 Cliente Flutter para VibeVoice - Índice completo

## 📂 Archivos creados para ti

### 🎯 Comienza aquí (por orden de uso)

1. **[FLUTTER_CHEATSHEET.md](FLUTTER_CHEATSHEET.md)** ⭐ **EMPIEZA AQUÍ**
   - Referencia rápida con copy & paste
   - Voces disponibles
   - Parámetros y configuración
   - Solución de problemas
   - **Tiempo de lectura: 5 minutos**

2. **[FLUTTER_README.md](FLUTTER_README.md)** 📖 **SEGUNDO**
   - Instalación paso a paso
   - Cómo integrar en tu proyecto
   - Conceptos clave en términos Flutter
   - Ejemplos de código
   - **Tiempo de lectura: 15 minutos**

3. **[flutter_demo_screen.dart](flutter_demo_screen.dart)** 🎨 **TERCERO**
   - Pantalla Flutter **completamente funcional**
   - **COPIA Y PEGA directamente a tu proyecto**
   - Interfaz profesional con:
     - Campo de texto
     - Selector de voces
     - Controles deslizantes (CFG Scale, Inference Steps)
     - Progreso en tiempo real
     - Indicador de estado
   - **Tiempo: 2 minutos para copiar**

### 📚 Archivos de referencia (consulta según necesites)

4. **[vibevoice_flutter_client.dart](vibevoice_flutter_client.dart)** 🔧
   - Servicio reutilizable `VibeVoiceTTSService`
   - Modelos de datos (`VibeVoiceGenerationState`)
   - Configuración (`VibeVoiceConfig`)
   - **Documenta todos los métodos disponibles**

5. **[flutter_client_example.dart](flutter_client_example.dart)** 💡
   - Explicaciones en términos Flutter
   - Comparaciones con widgets conocidos
   - Conceptos de Streams y WebSocket
   - Ejemplos de uso básico

6. **[flutter_advanced_examples.dart](flutter_advanced_examples.dart)** 🚀
   - Integración con Provider
   - Reproducción de audio automática
   - Chat con VibeVoice
   - Ejemplos avanzados comentados

---

## 🎯 Flujo recomendado de trabajo

### Día 1: Aprender lo básico

```
1. Leer FLUTTER_CHEATSHEET.md (5 min)
   ↓
2. Leer FLUTTER_README.md (15 min)
   ↓
3. Copiar flutter_demo_screen.dart a tu proyecto
   ↓
4. Ejecutar y ver funcionar
```

### Día 2: Integrar en tu app

```
1. Leer vibevoice_flutter_client.dart
   ↓
2. Adaptar el servicio a tu arquitectura
   ↓
3. Integrar con Provider (si lo usas)
   ↓
4. Añadir reproducción de audio
```

### Día 3+: Casos avanzados

```
1. Leer flutter_advanced_examples.dart
   ↓
2. Implementar chat con VibeVoice
   ↓
3. Caché y optimizaciones
   ↓
4. Interfaz personalizada
```

---

## 🚀 Inicio rápido (2 minutos)

### 1. Copiar el código

```bash
# Copiar el servicio a tu proyecto
cp vibevoice_flutter_client.dart tu_proyecto/lib/services/

# O copiar la pantalla completa
cp flutter_demo_screen.dart tu_proyecto/lib/screens/
```

### 2. Instalar dependencia

```yaml
# pubspec.yaml
dependencies:
  web_socket_channel: ^2.4.0
```

```bash
flutter pub get
```

### 3. Usar en tu app

```dart
import 'services/vibevoice_flutter_client.dart';

// En tu StatefulWidget:
late final VibeVoiceTTSService tts;

@override
void initState() {
  super.initState();
  tts = VibeVoiceTTSService();
  tts.init();
}

// Generar audio:
tts.generateSpeech(
  text: 'Hola mundo',
  voiceName: 'Carter (Hombre)',
);

// Escuchar estado:
tts.stateStream.listen((state) {
  print('Chunks: ${state.chunksReceived}');
});
```

---

## 📊 Comparación de archivos

| Archivo | Tamaño | Tipo | Usar cuando... |
|---------|--------|------|---|
| FLUTTER_CHEATSHEET.md | 5.8 KB | 📄 Referencia | Necesitas algo rápido |
| FLUTTER_README.md | 7.9 KB | 📖 Guía | Quieres entender bien |
| flutter_demo_screen.dart | 17 KB | 💻 Código | Necesitas una pantalla lista |
| vibevoice_flutter_client.dart | 13 KB | 🔧 Servicio | Necesitas el servicio |
| flutter_advanced_examples.dart | 16 KB | 🚀 Ejemplos | Quieres casos avanzados |
| flutter_client_example.dart | 5.1 KB | 💡 Tutorial | Prefieres explicaciones |

---

## 🎤 Voces disponibles

Puedes usar cualquiera de estas directamente en:
```dart
tts.generateSpeech(voiceName: 'Carter (Hombre)');
```

**Inglés:**
- Carter (Hombre) ⭐ RECOMENDADO
- Emma (Mujer)
- Frank (Hombre)
- Grace (Mujer)
- Mike (Hombre)
- Davis (Hombre)

**Otros idiomas:**
- Alemán, Francés, Italiano, Japonés, Coreano, Holandés, Polaco, Portugués, Español
- Cada uno en versiones (Hombre/Mujer)

---

## 📋 Checklist de integración

- [ ] Instalar `web_socket_channel`
- [ ] Copiar `vibevoice_flutter_client.dart`
- [ ] Crear `VibeVoiceTTSService` en initState
- [ ] Llamar `generateSpeech()` cuando necesites
- [ ] Escuchar `stateStream` para actualizar UI
- [ ] Llamar `dispose()` en destructor
- [ ] (Opcional) Añadir reproducción de audio
- [ ] (Opcional) Integrar con Provider

---

## ❓ Preguntas frecuentes

**P: ¿Necesito descagar el modelo de IA?**
A: No, el servidor lo trae. Solo necesitas que corra: `python demo/vibevoice_realtime_demo.py`

**P: ¿Cuánta latencia hay?**
A: ~300ms hasta escuchar el primer audio, luego streaming en tiempo real

**P: ¿Funciona sin internet?**
A: Solo si el servidor está en `localhost:3000`. Para producción, despliega en un servidor real.

**P: ¿Puedo personalizar las voces?**
A: No en esta versión, las voces vienen predefinidas del servidor.

**P: ¿Cómo reproduzco el audio?**
A: Usa `just_audio` (ver ejemplos avanzados). Por ahora, recibes los chunks en `audioStream`.

---

## 🔧 Requisitos

```
✓ Flutter 2.0+
✓ Dart 2.12+
✓ web_socket_channel: ^2.4.0
✓ VibeVoice servidor corriendo en localhost:3000
```

---

## 🎓 Aprenderás:

- ✅ WebSocket en Flutter
- ✅ Streams y StreamBuilder
- ✅ Integración con servicios externos
- ✅ Manejo de estado en tiempo real
- ✅ Descarga de datos en streaming

---

## 🤝 Soporte

Si tienes problemas:

1. **Revisa FLUTTER_CHEATSHEET.md** - Sección "⚠️ Errores comunes"
2. **Verifica que el servidor corre**: `curl http://localhost:3000/config`
3. **Mira los logs** en la terminal del servidor
4. **Consulta flutter_advanced_examples.dart** para casos especiales

---

## 📝 Notas importantes

1. **Siempre llama `dispose()`** cuando termines - libera el WebSocket
2. **CFG Scale 1.5** es el balance perfecto entre fidelidad y naturalidad
3. **Inference Steps 5** es rápido y buena calidad
4. **Los chunks llegan continuamente** - puedes reproducir mientras genera

---

## 🎯 Próximos pasos después de integrar

1. Añadir reproducción de audio automática
2. Crear caché de voces
3. Integrar con Provider para mejor estado
4. Hacer una UI personalizada
5. Añadir historial de generaciones

---

**Creado para que los desarrolladores Flutter integren VibeVoice en minutos. ¡Disfruta! 🎤**
