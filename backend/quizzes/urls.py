from django.urls import path
from .views import (
    QuizListView,
    QuizDetailView,
    LessonQuizzesView,
    SubmitQuiz,
    UserQuizAttemptsListView,
    UserQuizAttemptDetailView,
    LessonQuizzesListView,
)


urlpatterns = [
    path('', QuizListView.as_view(), name='quiz-list'),
    path('<int:quiz_id>/', QuizDetailView.as_view(), name='quiz-details'),
    path('lessons/<int:lesson_id>/', LessonQuizzesView.as_view(), name='lesson-quizzes'),
    path('submit/<int:quiz_id>/', SubmitQuiz.as_view(), name='submit-quiz'),
    path('attempts/', UserQuizAttemptsListView.as_view(), name='attempts-list'),
    path('attempts/<int:attempt_id>/',
         UserQuizAttemptDetailView.as_view(), name='attempt-details'),
    path('attempts/lessons/<int:lesson_id>/',
         LessonQuizzesListView.as_view(), name='lesson-quizzes-attempts-list'),
]