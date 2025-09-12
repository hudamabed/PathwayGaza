from rest_framework import serializers
from django.contrib.auth import get_user_model

from .models import Grade, Course, Lesson, LessonProgress


# ---------------------------
# Grade Serializer
# ---------------------------
class GradeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Grade
        fields = ['id', 'name', 'description']


# ---------------------------
# Lesson Serializer
# ---------------------------
class LessonSerializer(serializers.ModelSerializer):
    class Meta:
        model = Lesson
        fields = ['id', 'title', 'order', 'document_link', 'course']


# ---------------------------
# Course Serializer
# ---------------------------
class CourseSerializer(serializers.ModelSerializer):
    # Add a field to count lessons
    lessons_count = serializers.SerializerMethodField()
    # grade = GradeSerializer(read_only=True)  # nested grade info
    grade_id = serializers.PrimaryKeyRelatedField(
        queryset=Grade.objects.all(), source='grade', write_only=True
    )

    class Meta:
        model = Course
        fields = ['id', 'name', 'description', 'image_url',
                  'grade_id', 'lessons_count']

    def get_lessons_count(self, obj):
        # obj is the Course instance
        return obj.lessons.count()


# ---------------------------
# Lesson Progress Serializer
# ---------------------------
class LessonProgressSerializer(serializers.ModelSerializer):
    user = serializers.StringRelatedField(read_only=True)
    lesson = LessonSerializer(read_only=True)
    lesson_id = serializers.PrimaryKeyRelatedField(
        queryset=Lesson.objects.all(), source='lesson', write_only=True
    )

    class Meta:
        model = LessonProgress
        fields = ['id', 'user', 'lesson', 'lesson_id',
                  'is_completed', 'last_accessed']


class LessonProgressUpdateSerializer(serializers.Serializer):
    is_completed = serializers.BooleanField(
        required=True,
        help_text="Set to true to mark the lesson as completed"
    )
