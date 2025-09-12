from django.urls import path
from .views import (
    LessonProgressView
)

urlpatterns = [
    path('lessons/<int:lesson_id>/',
         LessonProgressView.as_view(), name='lesson-progress'),
]
