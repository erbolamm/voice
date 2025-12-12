import asyncio
import json
import math
from pathlib import Path
from fastapi import FastAPI, WebSocket, Request
from fastapi.responses import FileResponse
from starlette.websockets import WebSocketDisconnect

BASE = Path(__file__).parent
SAMPLE_RATE = 24000

app = FastAPI()

from aiortc import RTCPeerConnection, RTCSessionDescription, MediaStreamTrack
from av import AudioFrame
import numpy as np
import time


class SineAudioTrack(MediaStreamTrack):
    """A simple audio track that generates a sine wave."""
    kind = "audio"

    def __init__(self, sample_rate=24000, freq=220.0):
        super().__init__()
        self.sample_rate = sample_rate
        self.freq = freq
        self.phase = 0.0
        self.phase_inc = 2.0 * math.pi * self.freq / self.sample_rate
        # 20 ms frame
        self.frame_samples = int(self.sample_rate * 0.02)
        self._start_time = time.time()

    async def recv(self):
        # generate float32 frame
        data = np.zeros((self.frame_samples,), dtype=np.float32)
        for i in range(self.frame_samples):
            data[i] = math.sin(self.phase)
            self.phase += self.phase_inc

        # convert to 16-bit PCM and then to Frame
        # av.AudioFrame requires shape (channels, samples), float32
        frame = AudioFrame.from_ndarray(data, format="flt", layout="mono")
        frame.sample_rate = self.sample_rate
        # set presentation timestamp
        await asyncio.sleep(self.frame_samples / self.sample_rate)
        return frame


@app.post('/offer')
async def offer(request: Request):
    """Handle incoming SDP offers and return SDP answers."""
    params = await request.json()
    sdp = params.get("sdp")
    type_ = params.get("type")
    if not sdp or not type_:
        return {"error": "Invalid offer"}

    pc = RTCPeerConnection()
    track = SineAudioTrack(sample_rate=SAMPLE_RATE)
    pc.addTrack(track)

    # set remote description
    await pc.setRemoteDescription(RTCSessionDescription(sdp, type_))
    answer = await pc.createAnswer()
    await pc.setLocalDescription(answer)
    return {
        "sdp": pc.localDescription.sdp,
        "type": pc.localDescription.type,
    }


@app.get('/')
def index():
    return FileResponse(BASE / 'index.html')

@app.get('/config')
def config():
    # Provide the voices listed in demo/voices/streaming_model
    voices_dir = BASE.parent / 'voices' / 'streaming_model'
    voices = []
    try:
        for p in voices_dir.glob('*.pt'):
            voices.append(p.stem)
    except Exception:
        pass
    return {
        'voices': voices or ['en-Carter_man', 'en-Emma_woman'],
        'default_voice': voices[0] if voices else 'en-Carter_man',
    }

async def generate_sine_chunks(freq=220.0, duration_sec=60.0, chunk_ms=40):
    sample_count = int(SAMPLE_RATE * duration_sec)
    chunk_samples = int(SAMPLE_RATE * (chunk_ms / 1000.0))
    phase = 0.0
    phase_inc = 2.0 * math.pi * freq / SAMPLE_RATE
    generated = 0
    while generated < sample_count:
        buf = bytearray()
        for i in range(chunk_samples):
            v = math.sin(phase)
            pcm = int(max(-1.0, min(1.0, v)) * 32767)
            buf += pcm.to_bytes(2, 'little', signed=True)
            phase += phase_inc
        generated += chunk_samples
        await asyncio.sleep(chunk_ms / 1000.0)
        yield bytes(buf)

@app.websocket('/stream')
async def stream(ws: WebSocket):
    await ws.accept()
    try:
        # Parse query params
        q = dict(ws.scope.get('query_string') or b'')
        # send request received log
        await ws.send_text(json.dumps({
            'type': 'log',
            'event': 'backend_request_received',
            'data': {'text_length': 0, 'cfg_scale': 1.5, 'inference_steps': 5},
        }))

        first_chunk = True
        async for chunk in generate_sine_chunks(freq=220.0, duration_sec=30.0, chunk_ms=40):
            # After first chunk, send log
            if first_chunk:
                await ws.send_text(json.dumps({
                    'type': 'log',
                    'event': 'backend_first_chunk_sent',
                    'data': {},
                }))
                first_chunk = False
            await ws.send_bytes(chunk)
        # send final log
        await ws.send_text(json.dumps({
            'type': 'log',
            'event': 'backend_stream_complete',
            'data': {},
        }))
    except WebSocketDisconnect:
        return
    except Exception as e:
        try:
            await ws.send_text(json.dumps({
                'type': 'log',
                'event': 'backend_error',
                'data': {'message': str(e)},
            }))
        except Exception:
            pass
        finally:
            try:
                await ws.close()
            except Exception:
                pass
