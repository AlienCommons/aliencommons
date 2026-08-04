from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response


class StandardPagination(PageNumberPagination):
    def get_paginated_response_schema(self, schema):
        return {
            "type": "object",
            "required": [
                "count",
                "total_pages",
                "current_page",
                "page_size",
                "results",
            ],
            "properties": {
                "count": {"type": "integer", "example": 123},
                "total_pages": {"type": "integer", "example": 7},
                "current_page": {"type": "integer", "example": 1},
                "page_size": {"type": "integer", "example": 20},
                "results": schema,
            },
        }

    def get_paginated_response(self, data):
        return Response(
            {
                "count": self.page.paginator.count,
                "total_pages": self.page.paginator.num_pages,
                "current_page": self.page.number,
                "page_size": self.get_page_size(self.request),
                "results": data,
            }
        )
