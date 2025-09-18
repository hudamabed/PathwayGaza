from django.test import TestCase
from rest_framework.test import APITestCase, APIClient
from rest_framework import status
from django.urls import reverse
from django.contrib.auth import get_user_model

from learning.models import Lesson, Unit, Course, Grade
from .models import Quiz, Question, Answer, QuizAttempt


User = get_user_model()


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


class QuizViewsTests(APITestCase):
    def setUp(self):
        # Create a user and authenticate
        self.user = User.objects.create_user(
            email="test@example.com",
            username="testuser",
            password="password123"
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

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
            title="Quiz 1",
            description="This is a sample quiz",
            time_limit=30,
            max_score=100,
            min_score=50,
            lesson=self.lesson
        )

        # Create questions and answers
        self.question1 = Question.objects.create(text="Q1", points=10, quiz=self.quiz)
        self.answer1 = Answer.objects.create(text="A1", question=self.question1, is_correct=True)
        self.answer2 = Answer.objects.create(text="A2", question=self.question1, is_correct=False)

        self.question2 = Question.objects.create(text="Q2", points=5, quiz=self.quiz)
        self.answer3 = Answer.objects.create(text="A3", question=self.question2, is_correct=False)
        self.answer4 = Answer.objects.create(text="A4", question=self.question2, is_correct=True)

    def test_quiz_list_view(self):
        url = reverse('quiz-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['title'], "Quiz 1")

    def test_quiz_detail_view(self):
        url = reverse('quiz-details', kwargs={'quiz_id': self.quiz.id})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['title'], "Quiz 1")
        self.assertEqual(len(response.data['questions']), 2)

    def test_lesson_quizzes_list_view(self):
        url = reverse('lesson-quizzes', kwargs={'lesson_id': self.lesson.id})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        # self.assertIn("attempts", response.data[0])
        # self.assertEqual(response.data[0]["attempts"], [])

    def test_submit_quiz_view(self):
        url = reverse('submit-quiz', kwargs={'quiz_id': self.quiz.id})
        payload = {
            "answers": [
                {"question_id": self.question1.id, "selected_answer_id": self.answer1.id},  # correct
                {"question_id": self.question2.id, "selected_answer_id": self.answer3.id}   # incorrect
            ]
        }
        response = self.client.post(url, payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["score"], 10)  # only Q1 points counted
        self.assertEqual(len(response.data["user_answers"]), 2)

    def test_user_quiz_attempts_list_view(self):
        # Create a previous attempt
        attempt = QuizAttempt.objects.create(user=self.user, quiz=self.quiz, score=15)
        url = reverse('attempts-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["score"], 15)

    def test_user_quiz_attempt_detail_view(self):
        attempt = QuizAttempt.objects.create(user=self.user, quiz=self.quiz, score=20)
        url = reverse('attempt-details', kwargs={'attempt_id': attempt.id})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["score"], 20)
        self.assertEqual(response.data["quiz"], str(self.quiz))

    def test_lesson_quizzes_attempts_list_view(self):
        url = reverse('lesson-quizzes-attempts-list',
                       kwargs={'lesson_id': self.lesson.id})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertIn("attempts", response.data[0])
        self.assertEqual(response.data[0]["attempts"], [])
