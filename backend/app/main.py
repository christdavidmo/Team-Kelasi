from fastapi import FastAPI
from app.core.config import settings

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

@app.get("/health", tags=["System"])
def health_check():
    return {
        "status": "active",
        "project": settings.PROJECT_NAME,
        "version": "1.0.0"
    }