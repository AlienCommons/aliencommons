from rest_framework import serializers


class ApiMetaSchemaSerializer(serializers.Serializer):
    request_id = serializers.CharField(allow_null=True)
    timestamp = serializers.DateTimeField(allow_null=True)


class ApiErrorSchemaSerializer(serializers.Serializer):
    code = serializers.CharField()
    message = serializers.CharField()
    field = serializers.CharField(allow_null=True)


class ErrorEnvelopeSchemaSerializer(serializers.Serializer):
    success = serializers.ChoiceField(choices=[False], read_only=True)
    message = serializers.CharField()
    code = serializers.CharField()
    data = serializers.JSONField(allow_null=True)
    errors = ApiErrorSchemaSerializer(many=True)
    meta = ApiMetaSchemaSerializer()


class DeletedResultSchemaSerializer(serializers.Serializer):
    deleted = serializers.BooleanField()


class CountSchemaSerializer(serializers.Serializer):
    count = serializers.IntegerField(min_value=0)


class UpdatedCountSchemaSerializer(serializers.Serializer):
    updated = serializers.IntegerField(min_value=0)
