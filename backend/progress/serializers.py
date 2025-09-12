from rest_framework import serializers

from .models import LessonProgress
from learning.models import Lesson
from learning.serializers import LessonSerializer


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
