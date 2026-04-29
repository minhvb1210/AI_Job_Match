"""
app/core/responses.py

Standardized API response helpers.

All endpoints should return one of:
  success_response(data, message)
  error_response(message, data)
  paginated_response(items, total, page, limit)

Shape:
  {
    "success": true | false,
    "message": "...",
    "data": { ... } | null
  }
"""
from typing import Any, List, Optional


def success_response(data: Any = None, message: str = "") -> dict:
    """Return a successful API envelope."""
    return {
        "success": True,
        "message": message,
        "data": data,
    }


def error_response(message: str = "An error occurred", data: Any = None) -> dict:
    """Return an error API envelope."""
    return {
        "success": False,
        "message": message,
        "data": data,
    }


def paginated_response(
    items: List[Any],
    total: int,
    page: int,
    limit: int,
    message: str = "",
) -> dict:
    """Return a paginated success envelope."""
    return success_response(
        data={
            "items": items,
            "total": total,
            "page": page,
            "limit": limit,
            "pages": (total + limit - 1) // limit if limit > 0 else 1,
        },
        message=message,
    )
