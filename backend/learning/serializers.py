from rest_framework import serializers
from .models import Grade, Course, Lesson, Unit
from quizzes.models import Quiz


# ---------------------------
# Grade Serializer
# ---------------------------
class GradeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Grade
        fields = ['id', 'name', 'description']


class LessonSerializer(serializers.ModelSerializer):
    unit = serializers.PrimaryKeyRelatedField(read_only=True)
    quizzes = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Lesson
        fields = ['id', 'title', 'order', 'estimated_time',
                  'document_link', 'unit', 'quizzes']

    def get_quizzes(self, obj):
        # Get all quizzes that belong to lessons in this unit
        return [
            {"name": quiz.title, "duration": quiz.time_limit}
            for quiz in Quiz.objects.filter(lesson=obj)
        ]


class UnitWithLessonsSerializer(serializers.ModelSerializer):
    lessons = LessonSerializer(many=True, read_only=True)
    course = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Unit
        fields = ['id', 'title', 'description', 'course',
                  'order', 'lessons']
        
    def get_course(self, obj):
        return obj.course.id if obj else None


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
        return Lesson.objects.filter(unit__course=obj).count()
