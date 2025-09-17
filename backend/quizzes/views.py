from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from rest_framework.generics import get_object_or_404
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

from learning.models import Lesson
from .models import Quiz
from .serializers import QuizSerializer


class QuizListView(APIView):
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
            operation_id="quizzes_list",
        operation_description="Retrieve a list of all quizzes.",
        responses={200: QuizSerializer(many=True)}
    )
    def get(self, request):
        quizzes = Quiz.objects.all()
        serializer = QuizSerializer(quizzes, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class QuizDetailView(APIView):
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_id="quiz_details",
        operation_description="Retrieve details of a specific quiz by ID.",
        manual_parameters=[
            openapi.Parameter('quiz_id', openapi.IN_PATH, 
                              description="ID of the quiz", 
                              type=openapi.TYPE_INTEGER)
        ],
        responses={200: QuizSerializer()}
    )
    def get(self, request, quiz_id):
        quiz = get_object_or_404(Quiz, id=quiz_id)
        serializer = QuizSerializer(quiz)
        return Response(serializer.data, status=status.HTTP_200_OK)


class LessonQuizzesView(APIView):
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_id="lesson_quizzes",
        operation_description="Retrieve quizzes associated with a specific lesson.",
        manual_parameters=[
            openapi.Parameter('lesson_id', openapi.IN_PATH, 
                              description="ID of the lesson", 
                              type=openapi.TYPE_INTEGER)
        ],
        responses={200: QuizSerializer(many=True)}
    )
    def get(self, request, lesson_id):
        lesson = get_object_or_404(Lesson, id=lesson_id)
        quizzes = Quiz.objects.filter(lesson_id=lesson_id)
        serializer = QuizSerializer(quizzes, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
