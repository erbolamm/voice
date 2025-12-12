# VibeVoice Flutter Demo

Este subproyecto contiene una demo mínima para ejecutar las pantallas de ejemplo de VibeVoice.

Requisitos:
- Tener Flutter instalado y en el PATH (macOS: `brew install flutter` o seguir la guía oficial).

Pasos para ejecutar:

```bash
cd flutter_demo
flutter pub get
flutter run
```

Notas:
- El demo conecta a `ws://localhost:3000/stream` por defecto. Asegúrate de tener el servidor VibeVoice corriendo localmente para probar la reproducción en tiempo real.
- Las dependencias principales son: `web_socket_channel`, `just_audio`, `audio_session` y `provider`.

Si quieres, puedo ejecutar `flutter pub get` ahora y luego hacer commit y push de estos cambios. ¿Te parece bien?