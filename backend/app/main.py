import logging
from fastapi import FastAPI, Request
from fastapi import HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.database import engine, Base
from app.core.responses import error_response
from app.routers import auth, jobs, cv, applications, companies, notifications, ai, interviews, dashboard

# ── Ensure tables exist ──────────────────────────────────────────────────────
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="AI-JobMatch Platform",
    description="AI-powered job recommendation and CV matching backend.",
    version="2.0.0",
)

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5000",
        "http://127.0.0.1:5000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logger = logging.getLogger("ai_jobmatch")

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(auth.router)
app.include_router(jobs.router)
app.include_router(cv.router)
app.include_router(applications.router)
app.include_router(companies.router)
app.include_router(notifications.router)
app.include_router(ai.router)
app.include_router(interviews.router)
app.include_router(dashboard.router)


# ── Global Exception Handlers ─────────────────────────────────────────────────
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Handle known HTTP errors — return standard error envelope."""
    logger.warning("HTTPException %s: %s [%s %s]",
                   exc.status_code, exc.detail, request.method, request.url)
    return JSONResponse(
        status_code=exc.status_code,
        content=error_response(message=str(exc.detail)),
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle Pydantic / FastAPI validation errors — return 422 with detail."""
    errors = exc.errors()
    msg = "; ".join(
        f"{' -> '.join(str(loc) for loc in e['loc'])}: {e['msg']}"
        for e in errors
    )
    logger.warning("ValidationError [%s %s]: %s", request.method, request.url, msg)
    return JSONResponse(
        status_code=422,
        content=error_response(
            message="Validation error",
            data={"errors": errors},
        ),
    )


@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    """Catch-all for unexpected exceptions — log full traceback, return 500."""
    logger.exception("Unhandled exception [%s %s]: %s",
                     request.method, request.url, exc)
    return JSONResponse(
        status_code=500,
        content=error_response(message="Internal server error. Please try again later."),
    )


# ── Health check ──────────────────────────────────────────────────────────────
@app.get("/")
def read_root():
    return {"success": True, "message": "AI Job Match API is running", "data": None}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
