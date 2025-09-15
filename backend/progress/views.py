from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

from .serializers import (
    LessonProgressSerializer,
    LessonProgressUpdateSerializer,
    OverallProgressSerializer,
    LastActivitySerializer
)
from .models import LessonProgress
from learning.models import Lesson, Course
from learning.serializers import LessonSerializer


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
        operation_description="Access a lesson and update the access_time in DB for the authenticated user",
        responses={200: LessonProgressSerializer,
                   201: LessonProgressSerializer},
    )
    # TODO: only allow access if user completed the previous lesson (order - 1)
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
            progress = LessonProgress.objects.get(
                user=request.user, lesson=lesson)
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


class CourseProgressView(APIView):
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_id="get_course_progress",
        operation_description="Retrieve the authenticated user's progress for lessons in a given course. \
            Only lessons with progress are returned.",
        responses={200: LessonProgressSerializer(many=True)},
    )
    def get(self, request, course_id):
        # Ensure course exists
        course = get_object_or_404(Course, id=course_id)

        # Get progress entries for this user in this course
        progress_qs = LessonProgress.objects.filter(
            user=request.user,
            lesson__unit__course=course  # go via unit
        ).select_related("lesson", "lesson__unit")

        serializer = LessonProgressSerializer(progress_qs, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class OverallProgressSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_id="overall_lessons_progress_summary",
        operation_description="Get overall progress summary for all lessons for the authenticated user"
        + "(total lessons, completed lessons, completion percentage)",
        responses={200: OverallProgressSerializer},
    )
    def get(self, request):
        user = request.user
        if user.grade is None:
            return Response(
                {"detail": "User is not assigned to a grade."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # All lessons for the user's grade (via courses in that grade)
        total_lessons = Lesson.objects.filter(unit__course__grade=user.grade).count()

        # Lessons the user has completed
        completed_lessons = LessonProgress.objects.filter(
            user=user,
            is_completed=True,
            lesson__unit__course__grade=user.grade  # optional, if you want to restrict by grade
        ).count()

        # Calculate percentage
        completion_percentage = (
            (completed_lessons / total_lessons) *
            100 if total_lessons > 0 else 0.0
        )

        data = {
            "total_lessons": total_lessons,
            "completed_lessons": completed_lessons,
            "completion_percentage": round(completion_percentage, 2),
        }

        serializer = OverallProgressSerializer(data)
        return Response(serializer.data, status=status.HTTP_200_OK)


class LastActivityView(APIView):
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_id="last_accessed_lessons",
        operation_description="Get the last N accessed lessons for the authenticated user",
        manual_parameters=[
            openapi.Parameter(
                "limit",
                openapi.IN_QUERY,
                description="Number of records to return (default: 5)",
                type=openapi.TYPE_INTEGER,
            )
        ],
        responses={200: LastActivitySerializer(many=True)},
    )
    def get(self, request):
        limit = int(request.query_params.get("limit", 5))
        last_activities = (
            LessonProgress.objects
            .filter(user=request.user)
            .order_by("-last_accessed")[:limit]
        )
        serializer = LastActivitySerializer(last_activities, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
