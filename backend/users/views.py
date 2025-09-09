# users/views.py
from firebase_admin import auth
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from django.contrib.auth import get_user_model
from drf_yasg.utils import swagger_auto_schema

from .serializers import UserSerializer

User = get_user_model()


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_id="get_profile",
        operation_description="Retrieve current user's profile"
    )
    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    @swagger_auto_schema(
        operation_id="update_profile",
        operation_description="Update current user's profile"
    )
    def patch(self, request):
        serializer = UserSerializer(
            request.user, data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()

        new_display_name = serializer.validated_data.get('username')

        if new_display_name and new_display_name != request.user.username:
            try:
                firebase_uid = request.user.firebase_uid

                auth.update_user(
                    firebase_uid,
                    display_name=new_display_name
                )
                print(f"Firebase displayName updated successfully for UID: {firebase_uid}")

            except ValueError as e:
                # Handle Firebase errors gracefully
                print(f"Error updating Firebase displayName for UID {firebase_uid}: {e}")
                return Response(
                    "the specified user ID or properties are invalid.",
                    status=status.HTTP_400_BAD_REQUEST
                )
            except Exception as e:
                print(f"Error updating Firebase displayName for UID {firebase_uid}: {e}")
                return Response(
                    "this user is not registered on Firebase",
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        return Response(serializer.data, status=status.HTTP_200_OK)

