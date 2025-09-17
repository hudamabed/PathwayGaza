from django.test import TestCase

from learning.models import Lesson, Unit, Course, Grade
from .models import Quiz, Question, Answer


class QuizzesModelsTest(TestCase):
    def setUp(self):
        self.grade = Grade.objects.create(name="Grade 1")

        self.course = Course.objects.create(
            name="Math 101",
            description="Basic math course",
            grade=self.grade,
        )
        self.unit = Unit.objects.create(
            title="Unit 1",
            order=1,
            course=self.course
        )
        self.lesson = Lesson.objects.create(
            title="Lesson 1",
            order=1,
            unit=self.unit,
            document_link="http://example.com/lesson1.pdf"
        )

        # Create a Quiz
        self.quiz = Quiz.objects.create(
            title="Sample Quiz",
            description="This is a sample quiz",
            time_limit=30,
            max_score=100,
            min_score=50,
            lesson=self.lesson
        )

    def test_quiz_creation(self):
        """Test that a quiz can be created and string representation works"""
        self.assertEqual(self.quiz.title, "Sample Quiz")
        self.assertEqual(str(self.quiz), "Sample Quiz")
        self.assertEqual(self.quiz.lesson, self.lesson)

    def test_add_questions_to_quiz(self):
        """Test adding questions to a quiz"""
        q1 = Question.objects.create(text="What is 2+2?", points=10, quiz=self.quiz)
        q2 = Question.objects.create(text="What is Django?", points=20, quiz=self.quiz)

        self.assertEqual(self.quiz.questions.count(), 2)
        self.assertIn(q1, self.quiz.questions.all())
        self.assertIn(q2, self.quiz.questions.all())

    def test_add_answers_to_question(self):
        """Test adding answers to a question"""
        question = Question.objects.create(text="What is 2+2?", points=10, quiz=self.quiz)

        a1 = Answer.objects.create(text="3", is_correct=False, question=question)
        a2 = Answer.objects.create(text="4", is_correct=True, question=question)

        self.assertEqual(question.answers.count(), 2)
        self.assertIn(a1, question.answers.all())
        self.assertIn(a2, question.answers.all())
        self.assertTrue(a2.is_correct)

    def test_cascade_delete_quiz(self):
        """Test that deleting a quiz deletes related questions and answers"""
        question = Question.objects.create(text="What is 2+2?", points=10, quiz=self.quiz)
        Answer.objects.create(text="4", is_correct=True, question=question)

        self.quiz.delete()

        self.assertEqual(Question.objects.count(), 0)
        self.assertEqual(Answer.objects.count(), 0)

    def test_cascade_delete_question(self):
        """Test that deleting a question deletes related answers"""
        question = Question.objects.create(text="What is 2+2?", points=10, quiz=self.quiz)
        Answer.objects.create(text="4", is_correct=True, question=question)

        question.delete()

        self.assertEqual(Answer.objects.count(), 0)

    