# backend/app/api/routes/ai_routes.py
from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
import httpx, json, re, logging, time

from app.core.security import verify_token
from app.core.config   import settings

logger    = logging.getLogger(__name__)
ai_router = APIRouter()

# ════════════════════════════════════════════════════════
# نماذج الطلب
# ════════════════════════════════════════════════════════
class ParseCommandRequest(BaseModel):
    command:          str             = Field(..., min_length=1, max_length=2000)
    language:         str             = Field(default="ar")
    timeline_context: Dict[str, Any]  = Field(default={})
    available_effects:List[str]       = Field(default=[])

# ════════════════════════════════════════════════════════
# System Prompt للـ LLM
# ════════════════════════════════════════════════════════
SYSTEM_PROMPT = """أنت محرك تحليل أوامر لتطبيق مونتاج فيديو احترافي.
مهمتك: تحليل الأوامر العربية وتحويلها إلى JSON actions قابلة للتنفيذ.

التأثيرات المتاحة:
- apply_color_grade: (temperature, brightness, contrast, saturation, shadows, highlights, vignette, film_grain)
- remove_background: (model: mediapipe_selfie)
- motion_tracking:   (target_type: person/object)
- generate_captions: (language: auto)
- reduce_noise:      (strength: 0-1)
- add_music:         (mood: calm/sad/energetic/romantic, volume: 0-1)
- change_speed:      (speed_factor: 0.25-4.0)
- stabilize:         ()

قواعد الإخراج (JSON فقط، لا نص إضافي):
{"actions": [...], "confidence": 0.0-1.0}

كل action: {"type":"...", "target":"all|selected|clip_id", "parameters":{...}}
"""

# ════════════════════════════════════════════════════════
# تحليل الأمر
# ════════════════════════════════════════════════════════
@ai_router.post("/parse-command")
async def parse_command(
    req: ParseCommandRequest,
    current_user: dict = Depends(verify_token),
):
    t0 = time.time()
    actions = []
    confidence = 0.0

    # ── محاولة استخدام Anthropic Claude ──────────────────
    if settings.ANTHROPIC_API_KEY:
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                resp = await client.post(
                    "https://api.anthropic.com/v1/messages",
                    headers={
                        "x-api-key":          settings.ANTHROPIC_API_KEY,
                        "anthropic-version":  "2023-06-01",
                        "content-type":       "application/json",
                    },
                    json={
                        "model": "claude-haiku-4-5-20251001",
                        "max_tokens": 1024,
                        "system": SYSTEM_PROMPT,
                        "messages": [{
                            "role":    "user",
                            "content": f'الأمر: "{req.command}"\nالسياق: {json.dumps(req.timeline_context, ensure_ascii=False)}',
                        }],
                    },
                )
                resp.raise_for_status()
                raw    = resp.json()["content"][0]["text"]
                match  = re.search(r'\{.*\}', raw, re.DOTALL)
                if match:
                    parsed     = json.loads(match.group())
                    actions    = parsed.get("actions", [])
                    confidence = parsed.get("confidence", 0.9)
        except Exception as e:
            logger.warning(f"Anthropic call failed, falling back to rules: {e}")

    # ── Fallback: قواعد بسيطة ─────────────────────────────
    if not actions:
        actions, confidence = _rule_based_parse(req.command)

    return {
        "actions":            actions,
        "confidence":         confidence,
        "processing_time_ms": (time.time() - t0) * 1000,
        "requires_cloud":     any(a.get("type") in ["neural_style_transfer","audio_separation"]
                                  for a in actions),
    }

def _rule_based_parse(command: str):
    cmd  = command.lower()
    acts = []

    COLOR_MAP = {
        ("ليلي","أزرق ليلي","سينمائي ليلي"): {
            "type":"apply_color_grade","target":"all",
            "parameters":{"temperature":-0.3,"brightness":-0.15,"contrast":0.25,
                           "saturation":-0.1,"shadows":0.1,"highlights":-0.2}},
        ("دافئ","ذهبي","golden"): {
            "type":"apply_color_grade","target":"all",
            "parameters":{"temperature":0.3,"brightness":0.05,"contrast":0.15}},
        ("أبيض وأسود","بلاك"): {
            "type":"apply_color_grade","target":"all",
            "parameters":{"saturation":-1.0,"contrast":0.3}},
    }
    for keywords, action in COLOR_MAP.items():
        if any(k in cmd for k in keywords):
            acts.append(action); break

    if any(k in cmd for k in ("أزل الخلفية","إزالة الخلفية","ازل الخلفية")):
        acts.append({"type":"remove_background","target":"selected",
                     "parameters":{"model":"mediapipe_selfie"}})

    if any(k in cmd for k in ("ترجمة","subtitle","caption")):
        acts.append({"type":"generate_captions","target":"all",
                     "parameters":{"language":"auto"}})

    if any(k in cmd for k in ("ضوضاء","noise reduction")):
        acts.append({"type":"reduce_noise","target":"all_audio",
                     "parameters":{"strength":0.7}})

    if any(k in cmd for k in ("موسيقى هادئة","موسيقى")):
        mood = "calm" if "هادئ" in cmd else "energetic" if "حماسي" in cmd else "calm"
        acts.append({"type":"add_music","parameters":{"mood":mood,"volume":0.4}})

    if any(k in cmd for k in ("تتبع","tracking")):
        acts.append({"type":"motion_tracking","target":"selected",
                     "parameters":{"target_type":"person"}})

    if any(k in cmd for k in ("ثبّت","تثبيت","stabilize")):
        acts.append({"type":"stabilize","target":"all","parameters":{}})

    return acts, (0.7 if acts else 0.0)

@ai_router.get("/jobs/{job_id}/status")
async def job_status(job_id: str, current_user: dict = Depends(verify_token)):
    # [PLACEHOLDER] اتصل بـ Redis للحصول على حالة المهمة
    return {"job_id": job_id, "status": "processing", "progress": 0.0}
