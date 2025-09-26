from rest_framework import serializers

from .models import LessonProgress
from learning.models import Lesson
from learning.serializers import LessonSerializer


# ---------------------------
# Lesson Progress Serializer
# ---------------------------
class LessonProgressSerializer(serializers.ModelSerializer):
    user = serializers.StringRelatedField(read_only=True)
    lesson = serializers.SerializerMethodField()

    def get_lesson(self, obj):
        return {
            "id": obj.lesson.id,
            "name": obj.lesson.title
        }

    class Meta:
        model = LessonProgress
        fields = ['id', 'user', 'lesson', 'is_completed', 'last_accessed']


class LessonProgressUpdateSerializer(serializers.Serializer):
    is_completed = serializers.BooleanField(
        required=True,
        help_text="Set to true to mark the lesson as completed"
    )


class OverallProgressSerializer(serializers.Serializer):
    total_lessons = serializers.IntegerField()
    completed_lessons = serializers.IntegerField()
    completion_percentage = serializers.FloatField()


class OverallProgressWithRankSerializer(OverallProgressSerializer):
    top_percentile = serializers.FloatField()


class LastActivitySerializer(serializers.ModelSerializer):
    lesson = serializers.SerializerMethodField()

    def get_lesson(self, obj):
        return {
            "id": obj.lesson.id,
            "name": obj.lesson.title
        }

    class Meta:
        model = LessonProgress
        fields = ["id", "lesson", "is_completed", "last_accessed"]
