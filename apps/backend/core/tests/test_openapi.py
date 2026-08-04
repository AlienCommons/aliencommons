from django.test import SimpleTestCase
from drf_spectacular.generators import SchemaGenerator


class OpenApiSchemaTests(SimpleTestCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.schema = SchemaGenerator().get_schema(request=None, public=True)

    def test_success_responses_use_standard_envelope(self):
        response_schema = self.schema["paths"]["/v1/articles/"]["get"]["responses"]["200"]
        envelope = response_schema["content"]["application/json"]["schema"]

        self.assertEqual(
            set(envelope["required"]),
            {"success", "message", "code", "data", "errors", "meta"},
        )
        self.assertEqual(envelope["properties"]["success"]["enum"], [True])

    def test_paginated_data_matches_runtime_shape(self):
        response_schema = self.schema["paths"]["/v1/articles/"]["get"]["responses"]["200"]
        data_ref = response_schema["content"]["application/json"]["schema"]["properties"]["data"]["$ref"]
        component_name = data_ref.rsplit("/", 1)[-1]
        pagination = self.schema["components"]["schemas"][component_name]

        self.assertEqual(
            set(pagination["required"]),
            {"count", "total_pages", "current_page", "page_size", "results"},
        )
        self.assertNotIn("next", pagination["properties"])
        self.assertNotIn("previous", pagination["properties"])

    def test_write_action_uses_write_request_and_read_response(self):
        create = self.schema["paths"]["/v1/articles/"]["post"]
        request_ref = create["requestBody"]["content"]["application/json"]["schema"]["$ref"]
        response_ref = create["responses"]["201"]["content"]["application/json"]["schema"]["properties"]["data"]["$ref"]

        self.assertIn("ArticleWriteRequest", request_ref)
        self.assertIn("ArticleRead", response_ref)

    def test_destroy_is_documented_as_200_empty_envelope(self):
        responses = self.schema["paths"]["/v1/reactions/{id}/"]["delete"]["responses"]
        data_schema = responses["200"]["content"]["application/json"]["schema"]["properties"]["data"]

        self.assertNotIn("204", responses)
        self.assertTrue(data_schema["nullable"])

    def test_session_schema_documents_csrf_flow(self):
        csrf_operation = self.schema["paths"]["/v1/sessions/csrf/"]["get"]
        login_operation = self.schema["paths"]["/v1/sessions/login/"]["post"]

        self.assertEqual(csrf_operation["security"], [{}])
        self.assertIn(
            "CsrfToken",
            csrf_operation["responses"]["200"]["content"]["application/json"]["schema"]["properties"]["data"]["$ref"],
        )
        self.assertTrue(
            any(parameter["name"] == "X-CSRFToken" for parameter in login_operation["parameters"])
        )
