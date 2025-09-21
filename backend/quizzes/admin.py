from django.contrib import admin
from .models import Quiz, Question, Answer


class AnswerInline(admin.TabularInline):
    model = Answer
    extra = 2  # show 2 empty answer slots by default
    fields = ("text", "is_correct")
    show_change_link = True


class QuestionInline(admin.StackedInline):
    model = Question
    extra = 1  # show 1 empty question slot by default
    fields = ("text", "points")
    show_change_link = True


@admin.register(Quiz)
class QuizAdmin(admin.ModelAdmin):
    list_display = ("title", "lesson", "time_limit", "max_score", "min_score")
    search_fields = ("title", "description")
    list_filter = ("lesson",)
    inlines = [QuestionInline]


@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display = ("text", "quiz", "points")
    search_fields = ("text",)
    list_filter = ("quiz",)
    inlines = [AnswerInline]


@admin.register(Answer)
class AnswerAdmin(admin.ModelAdmin):
    list_display = ("text", "question", "is_correct")
    search_fields = ("text",)
    list_filter = ("is_correct", "question__quiz")
