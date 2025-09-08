from django.urls import path
from .views import GradeListView, CourseListView, LessonListView

urlpatterns = [
    # Get all grades
    path('grades/', GradeListView.as_view(), name='grade-list'),

    # Get all courses within a specific grade
    path('grades/<int:grade_id>/courses/',
         CourseListView.as_view(), name='course-list'),

    # Get all lessons within a specific course
    path('courses/<int:course_id>/lessons/',
         LessonListView.as_view(), name='lesson-list'),
]
