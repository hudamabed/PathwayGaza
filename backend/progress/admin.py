from django.contrib import admin
from .models import LessonProgress


@admin.register(LessonProgress)
class LessonProgressAdmin(admin.ModelAdmin):
    list_display = ("user", "lesson", "is_completed", "last_accessed")
    list_filter = ("is_completed", "last_accessed")
    search_fields = ("user__username", "user__email", "lesson__title")
    ordering = ("-last_accessed",)
    autocomplete_fields = ("user", "lesson")  # helps if you have many users/lessons
