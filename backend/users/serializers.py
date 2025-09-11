from rest_framework import serializers
from django.contrib.auth import get_user_model

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    grade_id = serializers.PrimaryKeyRelatedField(
        source="grade",
        queryset=User._meta.get_field(
            "grade").remote_field.model.objects.all(),
        required=False,
        allow_null=True,
    )

    class Meta:
        model = User
        fields = ["id", "email", "username",
                  "birth_date", "grade_id", "created_at"]
        read_only_fields = ["id", "created_at", "email"]

    def update(self, instance, validated_data):
        # Update username if provided
        username = validated_data.get("username")
        if username is not None and username != instance.username:
            instance.username = username

        # Update birth_date if provided
        birth_date = validated_data.get("birth_date")
        if birth_date is not None:
            instance.birth_date = birth_date

        # Update grade if provided
        grade = validated_data.get("grade")
        if grade is not None:
            instance.grade = grade

        instance.save(update_fields=["username", "birth_date", "grade"])
        return instance
