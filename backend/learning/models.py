from django.db import models


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


class Unit(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    order = models.PositiveIntegerField(
        help_text="Order of unit within the course")

    # relations (FKs)
    course = models.ForeignKey(
        Course, on_delete=models.CASCADE, related_name='units')

    class Meta:
        ordering = ["order"]
        # prevent duplicate order numbers
        unique_together = ("course", "order")

    def __str__(self):
        return self.title


class Lesson(models.Model):
    title = models.CharField(max_length=200)
    order = models.PositiveIntegerField(
        help_text="Order of lesson within the course")
    document_link = models.URLField(blank=True)
    estimated_time = models.PositiveIntegerField(
        help_text="Estimated time to complete the lesson in minutes",
        null=True,
        blank=True,
    )

    # relations (FKs)
    unit = models.ForeignKey(
        Unit,
        on_delete=models.CASCADE,
        related_name='lessons'
    )

    class Meta:
        ordering = ["unit__order", "order"]  # global ordering across units
        # prevent duplicate order numbers
        unique_together = ("unit", "order")

    def __str__(self):
        return f"{self.title} ({self.unit} - {self.unit.course})"
