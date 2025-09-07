from django.test import TestCase
from .models import Grade, Course, Lesson

from django.db import IntegrityError


class LearningModelsTest(TestCase):
    def setUp(self):
        # Create a grade
        self.grade1 = Grade.objects.create(
            name="Grade 1",
            description="First grade"
        )

        # Create courses for this grade
        self.course1 = Course.objects.create(
            name="Math 101",
            description="Basic Math",
            grade=self.grade1
        )
        self.course2 = Course.objects.create(
            name="Science 101",
            description="Basic Science",
            grade=self.grade1
        )

        # Create lessons for course1
        self.lesson1 = Lesson.objects.create(
            course=self.course1,
            title="Addition",
            order=1,
            document_link="http://example.com/addition"
        )
        self.lesson2 = Lesson.objects.create(
            course=self.course1,
            title="Subtraction",
            order=2,
            document_link="http://example.com/subtraction"
        )

    def test_course_relationship(self):
        # Grade -> courses reverse relationship
        self.assertEqual(list(self.grade1.courses.all()),
                         [self.course1, self.course2])

    def test_lesson_relationship(self):
        # Course -> lessons reverse relationship
        lessons = list(self.course1.lessons.all())
        self.assertEqual(lessons, [self.lesson1, self.lesson2])
        self.assertEqual(lessons[0].order, 1)

    def test_grade_name_unique(self):
        # Attempt to create another grade with the same name
        with self.assertRaises(IntegrityError):
            Grade.objects.create(
                name="Grade 1",  # same as the one in setUp
                description="Duplicate grade"
            )

    def test_unique_lesson_order(self):
        # Should raise IntegrityError if we try to duplicate order in same course
        with self.assertRaises(IntegrityError):
            Lesson.objects.create(
                course=self.course1,
                title="Duplicate Order",
                order=1,
                document_link="http://example.com/duplicate"
            )
