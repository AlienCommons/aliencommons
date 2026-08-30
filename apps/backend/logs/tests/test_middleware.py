from types import SimpleNamespace

from core.tests.testcases import BaseTestCase
from logs.logging.context import get_log_context
from logs.middleware import RequestLoggingMiddleware


class RequestLoggingMiddlewareTests(BaseTestCase):
    def test_logs_response_status_and_returns_response(self):
        request = SimpleNamespace(
            method="GET",
            path="/health/",
            request_id="req-123",
        )
        response = SimpleNamespace(status_code=204)
        middleware = RequestLoggingMiddleware(lambda _request: response)

        with self.assertLogs("logs.middleware", level="INFO") as captured:
            result = middleware(request)

        self.assertIs(result, response)
        self.assertIn(
            "Request completed: GET /health/ status=204",
            "\n".join(captured.output),
        )
        self.assertEqual(get_log_context(), {})
