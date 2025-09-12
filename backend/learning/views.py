from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework import status
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.contrib.auth import get_user_model
from drf_yasg.utils import swagger_auto_schema


from .models import Grade, Course, Lesson, LessonProgress
from .serializers import (
    GradeSerializer,
    CourseSerializer,
    LessonSerializer,
    LessonProgressSerializer,
    LessonProgressUpdateSerializer
)

User = get_user_model()


# ---------------------------
# Get all grades
# ---------------------------
class GradeListView(APIView):
    permission_classes = [AllowAny]

    @swagger_auto_schema(
        operation_id="get_grades_list",
        operation_description="Retrieve all available grades",
        security=[],
        responses={200: GradeSerializer},
    )
    def get(self, request):
        grades = Grade.objects.all()
        serializer = GradeSerializer(grades, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


# ---------------------------
# Get courses within a certain grade
# ---------------------------
class StudentCoursesListView(APIView):
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_id="get_courses_list",
        operation_description="Retrieve all courses for the authenticated user based on their grades",
        responses={200: CourseSerializer},
    )
    def get(self, request):
        grade = get_object_or_404(Grade, id=request.user.grade.id)
        courses = grade.courses.all()
        serializer = CourseSerializer(courses, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


# class CourseListView(APIView):
#     permission_classes = [AllowAny]

#     def get(self, request, grade_id):
#         grade = get_object_or_404(Grade, id=grade_id)
#         courses = grade.courses.all()
#         serializer = CourseSerializer(courses, many=True)
#         return Response(serializer.data, status=status.HTTP_200_OK)


# ---------------------------
# Get lessons within a certain course
# ---------------------------
class LessonListView(APIView):
    permission_classes = [AllowAny]

    @swagger_auto_schema(
        operation_id="get_lessons_list",
        operation_description="Retrieve all lessons for a certain course",
        responses={200: LessonSerializer},
    )
    def get(self, request, course_id):
        course = get_object_or_404(Course, id=course_id)
        lessons = course.lessons.all()
        serializer = LessonSerializer(lessons, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


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
