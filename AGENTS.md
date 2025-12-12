# Agent HQ - Orquestación de Agentes

## Resumen
Este archivo define agentes, roles y el flujo de trabajo de aprobación para la automatización de tareas en este repositorio.

> Requisito clave: TODOs planificados por el Plan Agent requieren **aprobación humana** antes de ejecución automatizada.

## Agentes y responsabilidades
- **Plan Agent**: Genera planes detallados de cambio y checklist; solicita aprobación humana.
- **Copilot Coding Agent**: Implementa cambios aprobados y abre PRs (marcados como draft hasta validación).
- **SecurityAgent**: Revisa dependencias, CVEs y busca secretos/credentials accidentales.
- **TestAgent**: Añade/ejecuta tests unitarios y de integración en `tests/`.
- **QAAgent**: Ejecuta pruebas end-to-end, valida streaming y audio.
- **DocAgent**: Actualiza documentación (`README.md`, `docs/`).

## Flujo de trabajo (Plan → Implementación)
1. El **Plan Agent** genera un plan en 3 fases y lo presenta como issue/PR para revisión humana.
2. Un desarrollador revisa y aprueba (comentario explícito en la issue/PR).
3. Tras la aprobación, el **Copilot Coding Agent** implementa los cambios en una rama nueva y abre un PR marcado como `draft` si procede.
4. CI ejecuta lint, tests y escaneo de seguridad; `SecurityAgent` y `TestAgent` añaden comentarios automatizados.
5. El PR se mantiene como `draft` hasta que pase los checks y un revisor humano lo apruebe.
6. Merge y release.

## Guardarraíles
- **Aprobación humana obligatoria**: Ningún PR generado por agentes se mergea sin una aprobación humana explícita.
- **No sobreescribir presets de voz** ni parámetros de inferencia sin justificación en la issue.
- Mantener las constantes de ventana streaming (`TTS_TEXT_WINDOW_SIZE`, `TTS_SPEECH_WINDOW_SIZE`) salvo acuerdo explícito.

## Conectividad y observabilidad
- Registrar agentes y servicios en MCP/Registry (si se usa); documentar pasos y secrets necesarios.
- Integrar observabilidad (Sentry/Datadog) y secret manager en entorno `devcontainer` o CI.

## Plan Agent — prompt recomendado (corto)
```
@PlanAgent: Genera un plan exhaustivo de 3 fases para preparar este repositorio para orquestación de agentes (Agent HQ). Fase 1: gobernanza y `AGENTS.md`; Fase 2: conectividad (MCP, observabilidad, extensions y devcontainer); Fase 3: flujo de delegación con aprobación humana obligatoria y PRs separados por agente. Devuelve: roadmap con tareas, estimaciones y archivos a crear (AGENTS.md, devcontainer, workflows, PR templates). Pide confirmación humana antes de ejecutar.
```

## Plantillas recomendadas a crear
- `AGENTS.md` (este archivo)
- `.devcontainer/devcontainer.json` (reproducibilidad de entorno)
- `.github/workflows/agent-ci.yml` (CI: lint, tests, security scan)
- `.github/PULL_REQUEST_TEMPLATE.md` (checklist de aprobación humana)
- `.github/ISSUE_TEMPLATE/agent-request.md` (para solicitudes de planificación)

## Archivos críticos para QA (ejemplos a revisar con agentes)
- `vibevoice/modular/streamer.py` — `AsyncAudioBatchIterator`, `AudioStreamer`.
- `vibevoice/modular/modular_vibevoice_tokenizer.py` — `SConv1d`, caching streaming.
- `vibevoice/processor/vibevoice_processor.py` — `VibeVoiceProcessor.from_pretrained`.

## Contacto
Mantén comunicación clara en las issues y añade la etiqueta `agent-generated` a PRs auto-creadas para facilitar la supervisión.
