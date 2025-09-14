from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework import status
from django.shortcuts import get_object_or_404
from django.contrib.auth import get_user_model
from drf_yasg.utils import swagger_auto_schema


from .models import Grade, Course
from .serializers import (
    GradeSerializer,
    CourseSerializer,
    LessonSerializer
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
        responses={200: GradeSerializer(many=True)},
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
        responses={200: CourseSerializer(many=True)},
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
        responses={200: LessonSerializer(many=True)},
    )
    def get(self, request, course_id):
        course = get_object_or_404(Course, id=course_id)
        lessons = course.lessons.all()
        serializer = LessonSerializer(lessons, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
