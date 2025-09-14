from django.urls import path
from .views import (
    LessonProgressView,
    CourseProgressView,
    OverallProgressSummaryView,
    LastActivityView
)

urlpatterns = [
    path('lessons/<int:lesson_id>/',
         LessonProgressView.as_view(), name='lesson-progress'),
    path('courses/<int:course_id>/lessons/',
         CourseProgressView.as_view(), name='course-progress'),
    path('lessons/summary/',
         OverallProgressSummaryView.as_view(), name='overall-progress-summary'),
    path('last-activity/',
         LastActivityView.as_view(), name='last-activity'),
]
