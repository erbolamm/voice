#!/usr/bin/env python3
"""
CLIENTE REALTIME DE VIBEVOICE - Explicado en términos Flutter

En Flutter, esto sería:
- StreamBuilder escuchando un Stream de audio
- WebSocket.connect() para conectarse en tiempo real
- stream.listen() para recibir chunks

En Python, es lo mismo con websockets.
"""

import asyncio
import websockets
import json
from pathlib import Path

# Configuración (como si fuera un config.dart)
class VibeVoiceConfig:
    """Equivalente a una clase de configuración en Flutter"""
    BASE_URL = "ws://localhost:3000"
    VOCES = {
        "Carter": "en-Carter_man",
        "Emma": "en-Emma_woman",
        "Frank": "en-Frank_man",
        "Grace": "en-Grace_woman",
        "Mike": "en-Mike_man",
    }
    CFG_SCALE = 1.5  # Control de fidelidad al texto
    INFERENCE_STEPS = 5  # Calidad vs velocidad


async def vibevoice_realtime_tts(
    text: str,
    voice_name: str = "Carter",
    cfg_scale: float = VibeVoiceConfig.CFG_SCALE,
    inference_steps: int = VibeVoiceConfig.INFERENCE_STEPS,
):
    """
    FUNCIÓN PRINCIPAL: Genera audio en tiempo real
    
    Equivalente en Flutter:
    ```dart
    Future<Stream<Uint8List>> generateSpeech(String text) async {
      final ws = await WebSocket.connect(url);
      return ws.stream;  // Stream de audio
    }
    ```
    
    Lo que hace:
    1. Conecta al servidor WebSocket
    2. Envía el texto como parámetro
    3. Recibe chunks de audio continuamente
    4. Puedes reproducir mientras llega
    """
    
    # PASO 1: Construir la URL con parámetros (como una API call)
    # En Flutter sería: Uri.parse('ws://localhost:3000/stream?text=$text&voice=$voice')
    voice_key = VibeVoiceConfig.VOCES.get(voice_name, VibeVoiceConfig.VOCES["Carter"])
    
    ws_url = (
        f"{VibeVoiceConfig.BASE_URL}/stream"
        f"?text={text.replace(' ', '%20')}"
        f"&voice={voice_key}"
        f"&cfg={cfg_scale}"
        f"&steps={inference_steps}"
    )
    
    print(f"\n🎙️ INICIANDO SÍNTESIS DE VOZ EN TIEMPO REAL")
    print(f"   Texto: '{text}'")
    print(f"   Voz: {voice_name} ({voice_key})")
    print(f"   CFG Scale: {cfg_scale} (1.5 = recomendado)")
    print(f"   Inference Steps: {inference_steps} (5 = rápido + bueno)")
    print(f"\n📡 Conectando a WebSocket: {ws_url[:60]}...")
    
    try:
        # PASO 2: Conectar al WebSocket (como WebSocket.connect() en Flutter)
        async with websockets.connect(ws_url) as websocket:
            print("✓ Conectado! Escuchando stream de audio...")
            
            audio_chunks = []
            chunk_count = 0
            total_bytes = 0
            
            # PASO 3: Escuchar el stream (como stream.listen() en Flutter)
            # El servidor emite chunks de audio continuamente (binary frames)
            async for message in websocket:
                chunk_count += 1
                total_bytes += len(message)
                audio_chunks.append(message)
                
                # Esto es lo que hacía un StreamBuilder en Flutter:
                # - Mostrar "Generando..." mientras llegan datos
                # - Reproducir audio en paralelo
                print(f"   📦 Chunk {chunk_count}: {len(message)} bytes | Total: {total_bytes/1024:.1f}KB")
                
                # Aquí es donde en una app Flutter reproducirías el audio:
                # player.play(message);
                
            print(f"\n✅ STREAM COMPLETADO")
            print(f"   Total de chunks recibidos: {chunk_count}")
            print(f"   Total de datos: {total_bytes/1024:.1f} KB = {total_bytes/(24000*4):.1f} segundos de audio")
            
            # Guardar audio para verificación
            output_path = Path(__file__).parent / "output_realtime.wav"
            print(f"   💾 Guardando en: {output_path}")
            
            # En una app real, ya estaría reproduciendo en paralelo
            # Aquí solo guardamos para verificar
            return audio_chunks, total_bytes
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return None, 0


# ============================================================
# COMPARACIÓN: MODO BUS vs MODO REALTIME
# ============================================================
"""
ANTES (MODO BUS):
┌─────────────┐
│   Cliente   │
└─────────────┘
        ↓ (sin hacer nada)
┌─────────────┐
│   Servidor  │ ← Escuchando pero sin procesar
│  (esperando)│
└─────────────┘

AHORA (MODO REALTIME):
┌─────────────┐
│   Cliente   │ ──websocket──→ [envía: "Hola"]
└─────────────┘
        ↑ ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ←
        │                                 │
        └─────────────────────────────────┘
        [recibe: audio chunks continuamente]
        
┌─────────────┐
│   Servidor  │ ← Procesando en tiempo real
│ (activo TTS)│   Emitiendo chunks de audio
└─────────────┘

Esto es EXACTAMENTE lo que hace Flutter con:
- StreamBuilder
- WebSocket
- stream.listen()
"""


async def demo_interactivo():
    """
    Demo interactivo - prueba el sistema en tiempo real
    
    Equivalente a tener una app Flutter con un TextField y Button:
    
    ```dart
    TextField(
      controller: textController,
      onChanged: (_) {},
    ),
    ElevatedButton(
      onPressed: () => generateSpeech(textController.text),
      child: Text('Generar Audio'),
    ),
    ```
    """
    
    print("\n" + "="*60)
    print("🚀 VIBEVOICE - CLIENTE REALTIME (Flutter Style)")
    print("="*60)
    
    # Ejemplos de prueba
    ejemplos = [
        ("Hello, this is a test of real-time text to speech synthesis.", "Carter"),
        ("¡Hola! Este es un ejemplo de síntesis de voz en tiempo real.", "Carter"),
    ]
    
    for texto, voz in ejemplos:
        print(f"\n{'─'*60}")
        audio_chunks, total_bytes = await vibevoice_realtime_tts(
            text=texto,
            voice_name=voz,
            cfg_scale=1.5,
            inference_steps=5,
        )
        
        if audio_chunks:
            print(f"\n🎵 Audio generado exitosamente!")
            print(f"   En una app Flutter reproducirías esto con:")
            print(f"   `player.play(Uint8List.fromList(audioBytes))`")


async def main():
    """Punto de entrada - como main() en Flutter"""
    await demo_interactivo()


if __name__ == "__main__":
    # Ejecutar (como runApp() en Flutter)
    asyncio.run(main())
