from django.http import JsonResponse
from django.views.csrf import csrf_failure as django_csrf_failure
from drf_std_response import build_payload


def csrf_failure(request, reason=""):
    if not request.path.startswith("/v1/"):
        return django_csrf_failure(request, reason=reason)

    payload = build_payload(
        success=False,
        message="Request failed",
        code="csrf_failed",
        data=None,
        errors=[
            {
                "code": "csrf_failed",
                "message": "CSRF validation failed",
                "field": None,
            }
        ],
        request=request,
    )
    return JsonResponse(payload, status=403)
