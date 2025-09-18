from rest_framework import serializers
from typing import List

from .models import (
    Quiz,
    Question,
    Answer,
    UserAnswer,
    QuizAttempt
)


class AnswerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Answer
        fields = ['id', 'text', 'is_correct']


class QuestionSerializer(serializers.ModelSerializer):
    answers = AnswerSerializer(many=True, read_only=True)

    class Meta:
        model = Question
        fields = ['id', 'text', 'answers']


class QuizSerializer(serializers.ModelSerializer):
    questions = QuestionSerializer(many=True, read_only=True)
    # Assuming lesson has a __str__ method
    lesson = serializers.StringRelatedField()

    class Meta:
        model = Quiz
        fields = ['id', 'title', 'description', 'lesson', 'questions']


class SubmitAnswerSerializer(serializers.Serializer):
    """
    Serializer for student submitting answers to a quiz.
    Example payload: { "question_id": 1, "selected_answer_id": 3 }
    """
    question_id = serializers.IntegerField()
    selected_answer_id = serializers.IntegerField()


class SubmitQuizSerializer(serializers.Serializer):
    """
    Serializer for quiz submission with multiple answers.
    """
    answers = SubmitAnswerSerializer(many=True)


class UserAnswerSerializer(serializers.ModelSerializer):
    question = serializers.StringRelatedField()
    selected_answer = serializers.StringRelatedField()

    class Meta:
        model = UserAnswer
        fields = ['id', 'question', 'selected_answer', 'is_correct']


class QuizAttemptSerializer(serializers.ModelSerializer):
    quiz = serializers.StringRelatedField()
    user_answers = UserAnswerSerializer(many=True, read_only=True)

    class Meta:
        model = QuizAttempt
        fields = ['id', 'quiz', 'score', 'attempted_at', 'user_answers']


class QuizResultsSerializer(serializers.ModelSerializer):
    """
    Serializer to return quiz results after submission.
    """
    user_answers = UserAnswerSerializer(many=True, read_only=True)

    class Meta:
        model = QuizAttempt
        fields = ['id', 'score', 'attempted_at', 'user_answers']


class UserQuizAttemptSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizAttempt
        fields = ['id', 'score', 'attempted_at']


class LessonQuizWithAttemptsSerializer(serializers.ModelSerializer):
    attempts = serializers.SerializerMethodField()

    class Meta:
        model = Quiz
        fields = ['id', 'title', 'description', 'time_limit', 'max_score', 'min_score', 'attempts']

    def get_attempts(self, obj) -> List:
        user = self.context['request'].user
        attempts = obj.attempts.filter(user=user).order_by('-attempted_at')
        return UserQuizAttemptSummarySerializer(attempts, many=True).data
