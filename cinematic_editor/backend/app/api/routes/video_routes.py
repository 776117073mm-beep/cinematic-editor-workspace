# backend/app/api/routes/video_routes.py
from fastapi import APIRouter, Depends, BackgroundTasks, UploadFile, File
from app.core.security import verify_token

video_router = APIRouter()

@video_router.post("/upload")
async def upload_video(
    file: UploadFile = File(...),
    folder: str = "uploads",
    current_user: dict = Depends(verify_token),
):
    # [PLACEHOLDER] ارفع الملف إلى S3 وأعد المفتاح
    return {"key": f"{folder}/{file.filename}", "url": "https://placeholder.url"}

@video_router.post("/export")
async def export_video(
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(verify_token),
):
    # [PLACEHOLDER] ابدأ مهمة التصدير السحابي
    return {"job_id": "export_placeholder", "status": "queued"}
