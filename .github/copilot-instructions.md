# VibeVoice AI Assistant Instructions

## Project Overview

VibeVoice is a research framework for generating expressive, long-form, multi-speaker conversational speech using a **next-token diffusion architecture**. The system combines an LLM backbone (Qwen2.5) with continuous speech tokenizers operating at ultra-low 7.5 Hz frame rates.

**Two model variants:**
- **Long-form multi-speaker**: Generates up to 90 minutes with 4 distinct speakers
- **Realtime streaming TTS** (`VibeVoice-Realtime-0.5B`): ~300ms first-audible latency, supports streaming text input

## Architecture

### Core Components

1. **Speech Tokenizers** (`vibevoice/modular/modular_vibevoice_tokenizer.py`)
   - **Acoustic tokenizer**: Continuous latent space at 7.5 Hz (not discrete tokens)
   - **Semantic tokenizer**: Only in long-form multi-speaker variant, removed in streaming model
   - VAE-based architecture with encoder/decoder for audio compression

2. **Model Hierarchy**
   ```
   VibeVoiceStreamingForConditionalGenerationInference (inference wrapper)
   └── VibeVoiceStreamingModel (core model)
       ├── Acoustic Tokenizer (speech encoder/decoder)
       ├── Language Model (Qwen2.5 0.5B/1.5B - text + speech generation)
       └── Diffusion Head (DPM-Solver++ for acoustic detail refinement)
   ```

3. **Generation Flow**
   - Text → Tokenizer → LM hidden states → Diffusion Head → Acoustic Decoder → Waveform
   - **Windowed streaming**: Processes text in chunks (TTS_TEXT_WINDOW_SIZE=5, TTS_SPEECH_WINDOW_SIZE=6)
   - **Interleaved processing**: Text encoding happens in parallel with acoustic generation

### Key Files

- Configuration: `vibevoice/modular/configuration_vibevoice_streaming.py` - Defines model architecture with sub-configs for tokenizer, decoder (Qwen2), and diffusion head
- Main model: `vibevoice/modular/modeling_vibevoice_streaming.py` - Base model implementation
- Inference model: `vibevoice/modular/modeling_vibevoice_streaming_inference.py` - Generation logic with streaming support
- Processor: `vibevoice/processor/vibevoice_streaming_processor.py` - Handles text+audio preprocessing
- Diffusion scheduler: `vibevoice/schedule/dpm_solver.py` - DPM-Solver++ for fast sampling

## Development Workflows

### Running Demos

**Realtime WebSocket demo** (preferred method):
```bash
python demo/vibevoice_realtime_demo.py --model_path microsoft/VibeVoice-Realtime-0.5B
```

**File-based inference**:
```bash
python demo/realtime_model_inference_from_file.py \
  --model_path microsoft/VibeVoice-Realtime-0.5B \
  --txt_path demo/text_examples/1p_vibevoice.txt \
  --speaker_name Carter
```

### Installation Pattern

**Always use Docker for CUDA environment** (recommended in docs):
```bash
docker run --privileged --gpus all --rm -it nvcr.io/nvidia/pytorch:24.07-py3
pip install -e .
```

Standard install works on CPU/MPS but may have dependency issues. Flash Attention 2 is critical for quality - SDPA fallback produces lower quality output.

### Device Handling

The codebase has specific device logic patterns:
- **CUDA**: Uses `bfloat16` + `flash_attention_2` + `device_map='cuda'`
- **MPS** (Apple Silicon): Uses `float32` + `sdpa` + manual `.to('mps')`  
- **CPU**: Uses `float32` + `sdpa` + `device_map='cpu'`

Note: "mpx" is treated as typo for "mps" (see `demo/web/app.py:49`)

### Voice Presets

Voice embeddings stored as `.pt` files in `demo/voices/streaming_model/`:
- Format: `{language}-{name}_{gender}.pt` (e.g., `en-Carter_man.pt`)
- Contains prefilled prompt tensors (`all_prefilled_outputs`)
- Loaded with `torch.load(..., map_location=device, weights_only=False)`
- **Critical**: Must use `copy.deepcopy()` when passing to generation to avoid state pollution

## Project Conventions

### Configuration Pattern

Models use composition with sub-configs:
```python
class VibeVoiceStreamingConfig(PretrainedConfig):
    sub_configs = {
        "acoustic_tokenizer_config": VibeVoiceAcousticTokenizerConfig,
        "decoder_config": Qwen2Config,
        "diffusion_head_config": VibeVoiceDiffusionHeadConfig,
    }
```

Each component can be initialized from dict or config instance.

### Generation Parameters

- `cfg_scale`: Classifier-free guidance (default: 1.5, range: 1.0-3.0)
- `do_sample`: Temperature sampling (default: False for deterministic)
- `temperature`/`top_p`: Only used when `do_sample=True`
- `inference_steps`: DDPM steps (default: 5, trade-off speed/quality)
- `refresh_negative`: Whether to refresh negative prompt in CFG

### Attention Implementation

**Critical requirement**: `flash_attention_2` is the only fully tested implementation. The code explicitly checks this:
```python
attn_impl_primary = "flash_attention_2"  # on CUDA
# If load fails, falls back to 'sdpa' with quality warning
```

### Streaming Architecture

Uses custom `AudioStreamer` class (`vibevoice/modular/streamer.py`):
- Queues audio chunks from generation thread
- Yields via iterator pattern: `for audio_chunk in streamer.get_stream(0)`
- Thread-safe with `Queue` and `threading.Event` for stopping
- WebSocket demo (`demo/web/app.py`) uses this pattern with `asyncio.Lock` for serialization

### Processor API

Two key methods in `VibeVoiceStreamingProcessor`:
1. `process_input_with_cached_prompt()` - Takes text + voice preset, returns model inputs
2. `save_audio()` - Converts acoustic latents to waveform, saves as WAV (24kHz)

## Integration Points

### Transformers Integration

Inherits from `PreTrainedModel` and `GenerationMixin` but uses custom generation logic:
- Override `generate()` with streaming/windowing support
- Uses `past_key_values` cache but with custom update logic
- Not compatible with standard `transformers>=4.52.0` (requires 4.51.3)

### External Dependencies

- `diffusers`: DPMSolverMultistepScheduler for diffusion sampling
- `librosa`: Audio processing utilities
- `aiortc`/`fastapi`/`uvicorn`: WebSocket streaming infrastructure
- `numba`/`llvmlite`: JIT compilation (for audio processing)

### Model Checkpoints

Models on HuggingFace Hub: `microsoft/VibeVoice-Realtime-0.5B`
- Uses standard HF `from_pretrained()` pattern
- Includes: model weights, configs, tokenizer, processor config

## Critical Gotchas

1. **Voice prompt caching**: Always deepcopy `all_prefilled_outputs` before passing to `generate()` - it gets mutated during generation
2. **Transformers version lock**: Pin to `transformers==4.51.3` - later versions incompatible
3. **Window sizes**: `TTS_TEXT_WINDOW_SIZE=5`, `TTS_SPEECH_WINDOW_SIZE=6` are hardcoded constants in inference code
4. **Quote normalization**: Text inputs should normalize quotes: `text.replace("'", "'")` before processing
5. **EOS detection**: Uses custom `BinaryClassifier` for TTS end-of-speech detection, not standard LM EOS token
6. **WebSocket concurrency**: Demo uses `asyncio.Lock` to serialize requests - only one generation at a time

## Responsible AI Considerations

- **Research-only**: Not for production use without further testing
- **Deepfake mitigation**: Voice presets embedded (no voice cloning from arbitrary samples)
- **Language support**: Primarily English (multilingual experimental in streaming model)
- **Disclosure**: Document explicitly states AI-generated audio must be disclosed

## Testing & Validation

No automated test suite present. Validation done via:
- Manual demo runs with example texts in `demo/text_examples/`
- Metrics: WER (Word Error Rate), Speaker Similarity on LibriSpeech/SEED benchmarks
- RTF (Real Time Factor) calculation in file inference script

When modifying generation code, test with both short (~1 sentence) and long-form (>1 minute) inputs to validate windowing logic.
