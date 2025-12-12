# Web Demo (Fast local test server)

This folder contains a web demo for VibeVoice realtime TTS. If you don't have a model or wish to quickly test the frontend, use the `fake_server.py` which streams a generated sine wave as PCM16 audio via WebSocket to the same endpoints expected by the real server.

Run the fake server:

```bash
python -m uvicorn demo.web.fake_server:app --reload --port 3000
```

Then open your browser to `http://localhost:3000/`.

If you have a real model and want to test the full pipeline, run the real server (requires a model):

```bash
export MODEL_PATH=microsoft/VibeVoice-Realtime-0.5B
export MODEL_DEVICE=cpu  # or cuda, or mps
python -m uvicorn demo.web.app:app --reload --port 3000
```

Notes:

WebRTC / Opus
---------------
- This demo also includes a WebRTC endpoint `/offer` (both the fake server and the real server) which allows the browser to establish a WebRTC PeerConnection and receive Opus-encoded audio.
- To use WebRTC playback from browser, click on `Start (WebRTC)`. The browser will create an SDP offer and the server will return an answer with the audio track.
- WebRTC requires `aiortc` and `av` installed. In a virtual environment:

```bash
python3 -m venv .venv_demo
source .venv_demo/bin/activate
pip install -r demo/web/requirements.txt
```

Then run the server as normal and open `http://127.0.0.1:3000/`.

Notes:
- The `/offer` endpoint currently uses a simple synthetic sine generator for the fake server. The real server implements a streaming `ModelAudioTrack` that wraps the model generation generator and will encode audio via Opus for WebRTC.
- WebRTC is more efficient since it uses Opus; for production, a proper STUN/TURN server and TLS is recommended.
