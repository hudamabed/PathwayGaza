# 🎓 PathwayGaza Platform

A **web-based educational platform** designed for students in Gaza, providing a complete learning roadmap from **kindergarten to high school**.  

The platform combines **Django REST Framework** as the backend with a **Flutter web** frontend to deliver structured courses, quizzes, and progress tracking.

---

## 📑 Table of Contents

- [✨ Features](#-features)
- [🛠 Tech Stack](#-tech-stack)
- [🏗️ Architecture Overview](#️-architecture-overview)
- [👥 Team Roles](#-team-roles)
- [🚀 How to Run](#-how-to-run)
  - [1️⃣ Backend (Django REST API)](#1%EF%B8%8F-backend-django-rest-api)
  - [2️⃣ Frontend (Flutter Web)](#2%EF%B8%8F-frontend-flutter-web)
- [🤝 Contributors](#-contributors)
---

## ✨ Features

- 🔑 **Authentication with Firebase** (Login / Signup)  
- 🏠 Personalized **student dashboard**  
- 📚 **Courses & lessons** organized by grade level  
- 📖 **Learning materials** with explanations and resources  
- 📝 **Quizzes** for each lesson to test understanding  
- 🌐 **Arabic language support**  
- 📈 Personal **progress tracking & grading**  
- 🗂️ **Django Admin Panel** for simple course and content management  
- 📶 *(Planned)* Offline support

---

## 🛠 Tech Stack

**Frontend:**  
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)  

**Backend:**  
![Django](https://img.shields.io/badge/Django_REST-092E20?style=for-the-badge&logo=django&logoColor=white)  

**Databases:**  
- ![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white) (Development)  
- ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white) (Production)  

**Authentication:**  
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)  

---

## 🏗️ Architecture Overview

- **Backend (Django REST Framework)**  
  - Organized into modular apps:
    - `users` → user profiles & Firebase integration  
    - `learning` → courses, lessons, materials  
    - `progress` → progress tracking & performance  
    - `quizzes` → lesson quizzes & results  
  - Built using Django’s **MVT pattern** (without templates — API only)  

- **Frontend (Flutter Web)**  
  - Connects to Django REST API  
  - Handles authentication via Firebase  

- **Admin**  
  - Django Admin Panel used for quick course and material management  
---
## 👥 Team Roles

| Name                | Role(s)                       | Responsitbilities                                  |
|---------------------|------------------------------|-----------------------------------------|
| Salsabeel Dwaikat   | Frontend Developer - Lead           | Flutter Web Developemnt |
| Mahmoud Khatib      | Backend Developer  | Django (DRF), DB Models    |
| Jenan Owies         | Frontend Developer           | UI/UX, Integration       |
| Huda A'abed         | QA and Testing            | Testing    |


---
# 🚀 How to Run
Follow these steps to set up and run the project locally:

## 1️⃣ Backend (Django REST API)

### Prerequisites
- Python 3.10+  
- pip / virtualenv  

### Setup
```bash
# Clone the repository
git clone https://github.com/<your-org>/<your-repo>.git
cd <your-repo>/backend

# Create and activate a virtual environment
python -m venv venv
source venv/bin/activate   # On Linux/Mac
venv\Scripts\activate      # On Windows

# Install dependencies
pip install -r requirements.txt

# Apply migrations
python manage.py migrate

# (Optional) Create superuser for Django Admin
python manage.py createsuperuser

# Run the development server
python manage.py runserver
```

## 2️⃣ Frontend (Flutter Web)
### Prerequisites

* Flutter SDK (3.35.4)
* Dart SDK (comes with Flutter)

```bash
cd ../frontend
# Get dependencies
flutter pub get

# Run in Chrome
flutter run -d chrome
```

---

## 🧪 Testing & Documentation

- **API Testing:** Postman was used to manually test all API endpoints.  
- **Unit Tests:** Unit tests were written for Django apps to ensure backend functionality.  
- **API Documentation:** Generated automatically using **Swagger UI**.  
  - Accessible at: `http://127.0.0.1:8000/swagger/` when running the backend server.

---

## 🤝 Contributors

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/hudamabed">
        <img src="https://avatars.githubusercontent.com/hudamabed" width="80" style="border-radius:50%;" />
      </a>
      <br>Huda A'abed
    </td>
    <td align="center">
      <a href="https://github.com/MahmoudKH02">
        <img src="https://avatars.githubusercontent.com/MahmoudKH02" width="80" style="border-radius:50%;" />
      </a>
      <br>Mahmoud KH
    </td>
    <td align="center">
      <a href="https://github.com/JenanOwies">
        <img src="https://avatars.githubusercontent.com/JenanOwies" width="80" style="border-radius:50%;" />
      </a>
      <br>Jenan Owies
    </td>
    <td align="center">
      <a href="https://github.com/salsabeelDwaikat">
        <img src="https://avatars.githubusercontent.com/salsabeelDwaikat" width="80" style="border-radius:50%;" />
      </a>
      <br>Salsabeel Dwaikat
    </td>
  </tr>
</table>