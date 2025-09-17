from django.urls import path
from .views import (
    QuizListView,
    QuizDetailView,
    LessonQuizzesView,
)


urlpatterns = [
    path('', QuizListView.as_view(), name='quiz-list'),
    path('<int:quiz_id>/', QuizDetailView.as_view(), name='quiz-details'),
    path('lessons/<int:lesson_id>/', LessonQuizzesView.as_view(), name='lesson-quizzes'),
]