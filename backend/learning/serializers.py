from rest_framework import serializers
from .models import Grade, Course, Lesson


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
