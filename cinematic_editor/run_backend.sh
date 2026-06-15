#!/usr/bin/env bash
# تشغيل السيرفر الخلفي
cd backend
[ ! -f .env ] && cp .env.example .env && echo "⚠️  عبّئ backend/.env قبل المتابعة"
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
