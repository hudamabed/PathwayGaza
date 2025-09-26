from django.urls import path
from .views import (
    LessonProgressView,
    CourseLessonsProgressView,
    OverallProgressView,
    LastActivityView,
    CourseOverallProgressView,
)

urlpatterns = [
    path('lessons/<int:lesson_id>/',
         LessonProgressView.as_view(), name='lesson-progress'),
    path('courses/<int:course_id>/lessons/',
         CourseLessonsProgressView.as_view(), name='course-lessons-progress'),
    path('courses/<int:course_id>/',
         CourseOverallProgressView.as_view(), name='course-progress'),
    path('courses/',
         OverallProgressView.as_view(), name='overall-progress'),
    path('last-activity/',
         LastActivityView.as_view(), name='last-activity'),
]
