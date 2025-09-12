from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_yasg.utils import swagger_auto_schema

from .serializers import LessonProgressSerializer, LessonProgressUpdateSerializer
from .models import LessonProgress
from learning.models import Lesson


# ---------------------------
# Progress in a lesson
# ---------------------------
class LessonProgressView(APIView):
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_id="get_lesson_progress",
        operation_description="Retrieve lesson progress for the authenticated user",
        responses={200: LessonProgressSerializer},
    )
    def get(self, request, lesson_id):
        lesson = get_object_or_404(Lesson, id=lesson_id)

        try:
            progress = LessonProgress.objects.get(user=request.user,
                                                  lesson=lesson)
        except LessonProgress.DoesNotExist:
            return Response(
                {"detail": "Lesson progress not found. Start the lesson first."},
                status=status.HTTP_404_NOT_FOUND,
            )
        serializer = LessonProgressSerializer(progress)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @swagger_auto_schema(
        operation_id="access_lesson",
        operation_description="Retrieve lesson progress for the authenticated user",
        responses={200: LessonProgressSerializer,
                   201: LessonProgressSerializer},
    )
    def post(self, request, lesson_id):
        lesson = get_object_or_404(Lesson, id=lesson_id)
        progress, created = LessonProgress.objects.get_or_create(
            user=request.user,
            lesson=lesson
        )
        progress.save()  # updates last_accessed
        serializer = LessonProgressSerializer(progress)
        return Response(serializer.data,
                        status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)

    @swagger_auto_schema(
        operation_id="update_lesson_progress",
        operation_description="Update lesson progress (is_completed) for the authenticated user",
        request_body=LessonProgressUpdateSerializer,
        responses={200: LessonProgressSerializer},
    )
    def patch(self, request, lesson_id):
        lesson = get_object_or_404(Lesson, id=lesson_id)

        try:
            progress = LessonProgress.objects.get(user=request.user, lesson=lesson)
        except LessonProgress.DoesNotExist:
            return Response(
                {"detail": "Cannot finish/update a lesson that has not been started."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Validate request data using serializer
        serializer = LessonProgressUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        is_completed = serializer.validated_data['is_completed']

        # Update progress
        progress.is_completed = is_completed
        progress.last_accessed = timezone.now()
        progress.save()

        # Return full LessonProgress info
        response_serializer = LessonProgressSerializer(progress)
        return Response(response_serializer.data, status=status.HTTP_200_OK)


# TODO: create endpoints to return overall progress
