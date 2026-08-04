from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter

CSRF_HEADER_PARAMETER = OpenApiParameter(
    name="X-CSRFToken",
    type=OpenApiTypes.STR,
    location=OpenApiParameter.HEADER,
    required=True,
    description="CSRF token returned by GET /v1/sessions/csrf/.",
)
