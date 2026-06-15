# backend/app/api/routes/auth_routes.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
from app.core.security import create_access_token

auth_router = APIRouter()

class LoginRequest(BaseModel):
    email:    EmailStr
    password: str

class RegisterRequest(BaseModel):
    email:       EmailStr
    password:    str
    device_id:   str
    device_name: str

@auth_router.post("/register")
async def register(req: RegisterRequest):
    # [PLACEHOLDER] تحقق من البريد الإلكتروني وأنشئ المستخدم في قاعدة البيانات
    token = create_access_token({"sub": "user_placeholder_id"})
    return {"access_token": token, "token_type": "bearer", "user_id": "placeholder"}

@auth_router.post("/login")
async def login(req: LoginRequest):
    # [PLACEHOLDER] تحقق من المستخدم في قاعدة البيانات
    token = create_access_token({"sub": "user_placeholder_id"})
    return {"access_token": token, "token_type": "bearer"}
