from rest_framework import serializers
from django.contrib.auth import get_user_model

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    # Make password optional now, because Firebase users won’t have it
    password = serializers.CharField(
        write_only=True, required=False, min_length=8
    )

    class Meta:
        model = User
        fields = ["id", "email", "username", "password", "created_at"]
        read_only_fields = ["id", "created_at"]

    def create(self, validated_data):
        # Only set password if provided
        password = validated_data.pop("password", None)
        user = User(**validated_data)

        if password:
            user.set_password(password)  # local user (superuser/admin)
        else:
            # Firebase-managed user: make password unusable
            user.set_unusable_password()

        user.save()
        return user

    def validate(self, attrs):
        # Prevent clients from setting staff/superuser fields
        if "is_staff" in self.initial_data or "is_superuser" in self.initial_data:
            raise serializers.ValidationError(
                "Not allowed to set staff or superuser fields."
            )
        return super().validate(attrs)

    def update(self, instance, validated_data):
        # Only allow username to be updated
        username = validated_data.get("username")

        if username != None and username != instance.username:
            instance.username = username
            instance.save(update_fields=["username"])
        return instance
