from copy import deepcopy

from drf_spectacular.openapi import AutoSchema


def _success_envelope_schema(data_schema):
    return {
        "type": "object",
        "required": ["success", "message", "code", "data", "errors", "meta"],
        "properties": {
            "success": {"type": "boolean", "enum": [True]},
            "message": {"type": "string"},
            "code": {"type": "string"},
            "data": data_schema,
            "errors": {
                "type": "array",
                "nullable": True,
                "items": {
                    "type": "object",
                    "required": ["code", "message", "field"],
                    "properties": {
                        "code": {"type": "string"},
                        "message": {"type": "string"},
                        "field": {"type": "string", "nullable": True},
                    },
                },
            },
            "meta": {
                "type": "object",
                "required": ["request_id", "timestamp"],
                "properties": {
                    "request_id": {"type": "string", "nullable": True},
                    "timestamp": {
                        "type": "string",
                        "format": "date-time",
                        "nullable": True,
                    },
                },
            },
        },
    }


class EnvelopeAutoSchema(AutoSchema):
    """Describe the success envelope applied at runtime by EnvelopeMixin."""

    def _get_action_mapping_value(self, mapping_name):
        mapping = getattr(self.view, mapping_name, {})
        key = (getattr(self.view, "action", None), self.method)
        if key in mapping:
            return True, mapping[key]
        action = getattr(self.view, "action", None)
        if action in mapping:
            return True, mapping[action]
        return False, None

    def get_request_serializer(self):
        found, serializer = self._get_action_mapping_value(
            "openapi_request_serializer_mapping"
        )
        if found:
            return serializer
        return super().get_request_serializer()

    def get_response_serializers(self):
        found, serializer = self._get_action_mapping_value(
            "openapi_response_serializer_mapping"
        )
        if found:
            return serializer

        serializer = super().get_response_serializers()
        action = getattr(self.view, "action", None)
        if action not in {"create", "update", "partial_update"}:
            return serializer

        serializer_class = serializer if isinstance(serializer, type) else serializer.__class__
        if not serializer_class.__name__.endswith(("WriteSerializer", "ModerationSerializer")):
            return serializer

        original_action = self.view.action
        try:
            self.view.action = "retrieve"
            response_serializer = self._get_serializer()
        finally:
            self.view.action = original_action
        return response_serializer or serializer

    def _get_response_bodies(self, direction="response"):
        response_serializers = self.get_response_serializers()
        if self.method == "DELETE" and not isinstance(response_serializers, dict):
            return {
                "200": self._get_response_for_code(
                    {"nullable": True},
                    "200",
                    direction=direction,
                )
            }
        return super()._get_response_bodies(direction)

    def _get_response_for_code(
        self,
        serializer,
        status_code,
        media_types=None,
        direction="response",
    ):
        response = super()._get_response_for_code(
            serializer,
            status_code,
            media_types,
            direction,
        )
        if not ("200" <= str(status_code) < "300"):
            return response

        response = deepcopy(response)
        content = response.get("content")
        if content:
            for media in content.values():
                media["schema"] = _success_envelope_schema(media["schema"])
        else:
            response["content"] = {
                media_type: {
                    "schema": _success_envelope_schema({"nullable": True}),
                }
                for media_type in self.map_renderers("media_type")
            }
        return response
