from django.db import models
from django.conf import settings


class Grade(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)

    def __str__(self):
        return self.name


class Course(models.Model):
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    image_url = models.URLField(null=True, blank=True)

    # relations (FKs)
    grade = models.ForeignKey(
        Grade, on_delete=models.CASCADE, related_name='courses')

    def __str__(self):
        return f"{self.name}, (Grade: {self.grade.name})"


class Lesson(models.Model):
    title = models.CharField(max_length=200)
    order = models.PositiveIntegerField(
        help_text="Order of lesson within the course")
    document_link = models.URLField(blank=True)

    # relations (FKs)
    course = models.ForeignKey(
        Course, on_delete=models.CASCADE, related_name='lessons')

    class Meta:
        ordering = ["order"]
        # prevent duplicate order numbers
        unique_together = ("course", "order")

    def __str__(self):
        return f"{self.title} (Course: {self.course.name})"


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
