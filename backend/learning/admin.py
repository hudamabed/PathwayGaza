from django.contrib import admin
from .models import Grade, Course, Lesson, Unit



class LessonInline(admin.TabularInline):
    model = Lesson
    extra = 1  # how many blank lessons to show by default
    fields = ("order", "title", "document_link")
    ordering = ("order",)


class UnitInline(admin.TabularInline):
    model = Unit
    extra = 1
    fields = ("order", "title", "description")
    ordering = ("id",)


@admin.register(Grade)
class GradeAdmin(admin.ModelAdmin):
    list_display = ("name", "description")
    search_fields = ("name", "description")


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ("name", "grade", "description")
    list_filter = ("grade",)
    search_fields = ("name", "description")
    inlines = [UnitInline]   # show Units under each Course


@admin.register(Unit)
class UnitAdmin(admin.ModelAdmin):
    list_display = ("title", "course", "order", "description")
    list_filter = ("course",)
    search_fields = ("title", "description")
    ordering = ("course", "order")
    inlines = [LessonInline]  # show lessons under each unit


@admin.register(Lesson)
class LessonAdmin(admin.ModelAdmin):
    list_display = ("title", "unit", "order", "document_link", "estimated_time")
    list_filter = ("unit__course", "unit")  # filter by course or unit
    search_fields = ("title", "document_link")
    ordering = ("unit", "order")
