from django.contrib import admin
from .models import Grade, Course, Lesson


class LessonInline(admin.TabularInline):
    model = Lesson
    extra = 1  # how many blank lessons to show by default
    fields = ("order", "title", "document_link")
    ordering = ("order",)


@admin.register(Grade)
class GradeAdmin(admin.ModelAdmin):
    list_display = ("name", "description")
    search_fields = ("name", "description")


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ("name", "grade", "description")
    list_filter = ("grade",)  # filter courses by grade in admin sidebar
    search_fields = ("name", "description")
    inlines = [LessonInline]


@admin.register(Lesson)
class LessonAdmin(admin.ModelAdmin):
    list_display = ("title", "course", "order", "document_link")
    list_filter = ("course",)
    search_fields = ("title", "document_link")
    ordering = ("course", "order")
