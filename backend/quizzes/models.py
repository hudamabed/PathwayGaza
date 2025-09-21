from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError


class Quiz(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    time_limit = models.PositiveIntegerField(help_text="Time limit in minutes")
    max_score = models.PositiveIntegerField()
    min_score = models.PositiveIntegerField()

    # relations (FKs)
    lesson = models.ForeignKey(
        'learning.lesson', on_delete=models.CASCADE, related_name='quizzes')

    def __str__(self):
        return self.title


class Question(models.Model):
    text = models.TextField()
    points = models.PositiveIntegerField()

    # relations (FKs)
    quiz = models.ForeignKey(
        Quiz, on_delete=models.CASCADE, related_name='questions')

    def __str__(self):
        return self.text[:50]  # Return first 50 characters of the question


class Answer(models.Model):
    text = models.CharField(max_length=500)
    is_correct = models.BooleanField(default=False)

    # relations (FKs)
    question = models.ForeignKey(
        Question, on_delete=models.CASCADE, related_name='answers')
    
    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["question"],
                condition=models.Q(is_correct=True),
                name="unique_correct_answer_per_question",
            )
        ]

    def clean(self):
        # If this answer is marked correct, ensure no other correct answer exists
        if self.is_correct:
            existing_correct = Answer.objects.filter(
                question=self.question,
                is_correct=True
            ).exclude(pk=self.pk)  # exclude self when updating
            if existing_correct.exists():
                raise ValidationError("Only one correct answer is allowed per question.")

    def __str__(self):
        return self.text[:50]  # Return first 50 characters of the answer


class QuizAttempt(models.Model):
    score = models.FloatField()
    attempted_at = models.DateTimeField(auto_now_add=True)

    # relations (FKs)
    quiz = models.ForeignKey(
        Quiz, on_delete=models.CASCADE, related_name='attempts')
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='quiz_attempts')

    def __str__(self):
        return f"{self.user.username} - {self.quiz.title} - {self.score}"


class UserAnswer(models.Model):
    is_correct = models.BooleanField()

    # relations (FKs)
    attempt = models.ForeignKey(
        QuizAttempt, on_delete=models.CASCADE, related_name='user_answers')
    question = models.ForeignKey(
        Question, on_delete=models.CASCADE, related_name='user_answers')
    selected_answer = models.ForeignKey(
        Answer, on_delete=models.CASCADE, related_name='user_answers')

    def __str__(self):
        return f"{self.attempt.user.username} - {self.question.text[:30]} \
            - {self.selected_answer.text[:30]} - {'Correct' if self.is_correct else 'Incorrect'}"
