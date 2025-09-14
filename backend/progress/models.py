from django.db import models
from django.conf import settings

from learning.models import Lesson


class LessonProgress(models.Model):
    is_completed = models.BooleanField(default=False)
    last_accessed = models.DateTimeField(auto_now=True)

    # relations (FKs)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='lesson_progress'
    )
    lesson = models.ForeignKey(
        Lesson, on_delete=models.CASCADE, related_name='progress')

    class Meta:
        unique_together = ('user', 'lesson')

    def __str__(self):
        return f"{self.user} - {self.lesson}: ({'Completed' if self.is_completed else 'In Progress'})"
