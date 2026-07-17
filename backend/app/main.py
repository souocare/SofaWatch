from fastapi import FastAPI

app = FastAPI(
    title="SofaWatch API",
    description="Self-hosted API for tracking television shows and movies.",
    version="0.1.0",
)


@app.get("/")
async def root() -> dict[str, str]:
    return {
        "name": "SofaWatch API",
        "status": "running",
    }


@app.get("/api/v1/health")
async def health_check() -> dict[str, str]:
    return {
        "status": "healthy",
    }