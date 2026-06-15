# backend/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from contextlib import asynccontextmanager
import uvicorn, logging

from app.core.config import settings
from app.api.routes.ai_routes    import ai_router
from app.api.routes.auth_routes  import auth_router
from app.api.routes.video_routes import video_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("🚀 Cinematic Editor API starting...")
    yield
    logger.info("🛑 Shutting down...")

app = FastAPI(
    title="Cinematic Editor API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"])
app.add_middleware(GZipMiddleware, minimum_size=1000)

app.include_router(auth_router,  prefix="/v1/auth",  tags=["Auth"])
app.include_router(ai_router,    prefix="/v1/ai",    tags=["AI"])
app.include_router(video_router, prefix="/v1/video", tags=["Video"])

@app.get("/health")
async def health():
    return {"status": "healthy", "version": "1.0.0"}

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
