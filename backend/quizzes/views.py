from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from rest_framework.generics import get_object_or_404
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

from learning.models import Lesson
from .models import Quiz, Question, Answer, QuizAttempt, UserAnswer
from .serializers import (
    QuizSerializer,
    SubmitQuizSerializer,
    QuizResultsSerializer,
    QuizAttemptSerializer,
    LessonQuizWithAttemptsSerializer,
)


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


class SubmitQuiz(APIView):
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_id="submit_quiz",
        operation_description="Submit answers for a quiz and calculate the score.",
        request_body=SubmitQuizSerializer,
        responses={200: QuizResultsSerializer()},
    )
    def post(self, request, quiz_id):
        quiz = get_object_or_404(Quiz, id=quiz_id)
        serializer = SubmitQuizSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        answers_data = serializer.validated_data['answers']

        score = 0
        user_answers = []

        # calculate score first
        for ans in answers_data:
            question = get_object_or_404(
                Question, id=ans['question_id'], quiz=quiz)
            selected_answer = get_object_or_404(
                Answer, id=ans['selected_answer_id'], question=question)

            if selected_answer.question.id != question.id:
                return Response({"detail": "Selected answer does not belong to the question."},
                                status=status.HTTP_400_BAD_REQUEST)

            is_correct = selected_answer.is_correct
            if is_correct:
                score += question.points

            user_answers.append({
                "question": question,
                "selected_answer": selected_answer,
                "is_correct": is_correct,
            })

        # now create the attempt with final score
        attempt = QuizAttempt.objects.create(
            user=request.user, quiz=quiz, score=score)

        # bulk create UserAnswer entries
        UserAnswer.objects.bulk_create([
            UserAnswer(
                attempt=attempt,
                question=ua["question"],
                selected_answer=ua["selected_answer"],
                is_correct=ua["is_correct"]
            )
            for ua in user_answers
        ])

        results_serializer = QuizResultsSerializer(attempt)
        return Response(results_serializer.data, status=status.HTTP_200_OK)


class UserQuizAttemptsListView(APIView):
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_id="user_quiz_attempts_list",
        operation_description="List all quiz attempts by the authenticated user.",
        responses={200: QuizAttemptSerializer(many=True)},
    )
    def get(self, request):
        attempts = QuizAttempt.objects.filter(user=request.user).select_related("quiz")
        serializer = QuizAttemptSerializer(attempts, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class UserQuizAttemptDetailView(APIView):
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_id="user_quiz_attempt_detail",
        operation_description="Retrieve details of a specific quiz attempt.",
        manual_parameters=[
            openapi.Parameter('attempt_id', openapi.IN_PATH, description="ID of the quiz attempt",
                              type=openapi.TYPE_INTEGER)
        ],
        responses={200: QuizAttemptSerializer()},
    )
    def get(self, request, attempt_id):
        attempt = get_object_or_404(QuizAttempt, id=attempt_id, user=request.user)
        serializer = QuizAttemptSerializer(attempt)
        return Response(serializer.data, status=status.HTTP_200_OK)


class LessonQuizzesListView(APIView):
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_id="lesson_quizzes_list",
        operation_description="Retrieve a list of quizzes for a lesson with user's attempts (score, max/min score only).",
        manual_parameters=[
            openapi.Parameter(
                'lesson_id',
                openapi.IN_PATH,
                description="ID of the lesson",
                type=openapi.TYPE_INTEGER
            )
        ],
        responses={200: LessonQuizWithAttemptsSerializer(many=True)},
    )
    def get(self, request, lesson_id):
        lesson = get_object_or_404(Lesson, id=lesson_id)
        quizzes = Quiz.objects.filter(lesson=lesson).prefetch_related("attempts")
        serializer = LessonQuizWithAttemptsSerializer(quizzes, many=True, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)
