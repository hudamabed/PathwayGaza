from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework import status
from django.shortcuts import get_object_or_404
from django.utils import timezone

from .models import Grade, Course, Lesson, CourseEnrollment, LessonProgress
from .serializers import (
    GradeSerializer,
    CourseSerializer,
    LessonSerializer,
    CourseEnrollmentSerializer,
    LessonProgressSerializer
)


# ---------------------------
# Get all grades
# ---------------------------
class GradeListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        grades = Grade.objects.all()
        serializer = GradeSerializer(grades, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


# ---------------------------
# Get courses within a certain grade
# ---------------------------
class CourseListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, grade_id):
        grade = get_object_or_404(Grade, id=grade_id)
        courses = grade.courses.all()
        serializer = CourseSerializer(courses, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


# ---------------------------
# Enroll in a course
# ---------------------------
class EnrollCourseView(APIView):
    def post(self, request, course_id):
        course = get_object_or_404(Course, id=course_id)
        enrollment, created = CourseEnrollment.objects.get_or_create(
            user=request.user,
            course=course
        )
        if not created:
            return Response({"detail": "Already enrolled in this course."},
                            status=status.HTTP_400_BAD_REQUEST)

        serializer = CourseEnrollmentSerializer(enrollment)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


# ---------------------------
# Get lessons within a certain course
# ---------------------------
class LessonListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, course_id):
        course = get_object_or_404(Course, id=course_id)
        lessons = course.lessons.all()
        serializer = LessonSerializer(lessons, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


# ---------------------------
# Start a lesson
# ---------------------------
class StartLessonView(APIView):
    def post(self, request, lesson_id):
        lesson = get_object_or_404(Lesson, id=lesson_id)
        progress, created = LessonProgress.objects.get_or_create(
            user=request.user,
            lesson=lesson
        )
        serializer = LessonProgressSerializer(progress)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


# ---------------------------
# Access a lesson (update last_accessed)
# ---------------------------
class AccessLessonView(APIView):
    def post(self, request, lesson_id):
        lesson = get_object_or_404(Lesson, id=lesson_id)
        progress = get_object_or_404(
            LessonProgress, user=request.user, lesson=lesson)
        progress.save()
        serializer = LessonProgressSerializer(progress)
        return Response(serializer.data, status=status.HTTP_200_OK)


# ---------------------------
# Finish a lesson
# ---------------------------
class FinishLessonView(APIView):
    def post(self, request, lesson_id):
        lesson = get_object_or_404(Lesson, id=lesson_id)
        progress, _ = LessonProgress.objects.get_or_create(
            user=request.user, lesson=lesson)
        progress.is_completed = True
        progress.last_accessed = timezone.now()
        progress.save()
        serializer = LessonProgressSerializer(progress)
        return Response(serializer.data, status=status.HTTP_200_OK)


# ---------------------------
# Finish a course
# ---------------------------
class FinishCourseView(APIView):
    def post(self, request, course_id):
        course = get_object_or_404(Course, id=course_id)
        enrollment = get_object_or_404(
            CourseEnrollment, user=request.user, course=course)
        enrollment.finish_date = timezone.now()
        enrollment.save()
        serializer = CourseEnrollmentSerializer(enrollment)
        return Response(serializer.data, status=status.HTTP_200_OK)
