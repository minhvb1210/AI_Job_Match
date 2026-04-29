"""
app/services/ai/preprocessing.py

Text extraction and cleaning utilities.
"""
import re
from io import BytesIO

import pytesseract
from PIL import Image, ImageEnhance
from unidecode import unidecode
import PyPDF2
from docx import Document
import nltk
import platform

try:
    nltk.download("stopwords", quiet=True)
    from nltk.corpus import stopwords
    _stop_words = set(stopwords.words("english"))
except Exception:
    _stop_words = {
        "i", "me", "my", "we", "our", "you", "your", "he", "him", "his",
        "she", "her", "it", "its", "they", "them", "their", "what", "which",
        "who", "this", "that", "these", "those", "am", "is", "are", "was",
        "were", "be", "been", "being", "have", "has", "had", "do", "does",
        "did", "a", "an", "the", "and", "but", "if", "or", "as", "of",
        "at", "by", "for", "with", "in", "out", "on", "off", "to", "from",
        "up", "down", "then", "here", "there", "all", "any", "no", "not",
        "own", "so", "than", "too", "very", "can", "will", "just", "should",
    }

# OS-based Tesseract path detection
if platform.system() == "Windows":
    pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
else:
    # Linux (Docker)
    pytesseract.pytesseract.tesseract_cmd = r"/usr/bin/tesseract"


def clean_text(text: str) -> str:
    """Lowercase, remove accents, strip special characters."""
    if not text:
        return ""
    text = text.lower()
    text = unidecode(text)
    text = re.sub(r"[^a-zA-Z0-9\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def preprocess_text(text: str) -> str:
    """Clean then remove stop-words."""
    cleaned = clean_text(text)
    words = cleaned.split()
    return " ".join(w for w in words if w not in _stop_words)


def extract_text_from_pdf(file_bytes: bytes) -> str:
    reader = PyPDF2.PdfReader(BytesIO(file_bytes))
    return "\n".join(page.extract_text() or "" for page in reader.pages)


def extract_text_from_docx(file_bytes: bytes) -> str:
    doc = Document(BytesIO(file_bytes))
    return "\n".join(para.text for para in doc.paragraphs)


def extract_text_from_image(file_bytes: bytes) -> str:
    image = Image.open(BytesIO(file_bytes))

    # Upscale if too small (Tesseract needs ≥300 DPI equivalent)
    w, h = image.size
    if w < 1500:
        image = image.resize((w * 2, h * 2), Image.Resampling.LANCZOS)

    # Grayscale → contrast → sharpness → binarize
    image = image.convert("L")
    image = ImageEnhance.Contrast(image).enhance(2.0)
    image = ImageEnhance.Sharpness(image).enhance(1.5)
    image = image.point(lambda p: 255 if p > 150 else 0)

    return pytesseract.image_to_string(image, config="--psm 3")
