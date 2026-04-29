import logging
import sys
import os

# Create logs directory if it doesn't exist
if not os.path.exists("logs"):
    os.makedirs("logs")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler("logs/app.log", encoding="utf-8")
    ]
)

logger = logging.getLogger("ai_jobmatch")

# Dedicated logger for AI scoring
ai_logger = logging.getLogger("ai_scoring")
ai_logger.setLevel(logging.INFO)
ai_handler = logging.FileHandler("logs/ai_scoring.log", encoding="utf-8")
ai_handler.setFormatter(logging.Formatter("%(asctime)s: %(message)s"))
ai_logger.addHandler(ai_handler)

def get_logger(name: str):
    return logging.getLogger(name)
