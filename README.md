# 🎮 Smart Games Solver

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![FastAPI](https://img.shields.io/badge/FastAPI-0.109-009688?logo=fastapi)
![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791?logo=postgresql)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

*A cross-platform mobile application featuring classic puzzle games, AI-powered solvers, leaderboards, and social features.*

</div>

---

## 📖 Overview

**Smart Games Solver** is a Flutter and FastAPI-based mobile application that combines entertainment with problem-solving. The project follows **Clean Architecture** to ensure scalability, maintainability, and modular development.

## ✨ Features

### 🎮 Games

* **2048**

  * High score tracking
  * Undo & move suggestions
  * Global leaderboard

* **Sudoku**

  * 4 difficulty levels
  * Smart hint system
  * Real-time validation
  * Notes and timer

* **Gomoku (Caro)**

  * Play against AI (4 difficulty levels)
  * AI vs AI mode
  * Minimax + Alpha-Beta Pruning

* **Rubik's Cube Solver**

  * Kociemba algorithm (≤20 moves)
  * Camera scanning or manual input
  * Step-by-step solution

### 👥 Social Features

* User authentication (JWT)
* Friend system
* Real-time chat
* Notifications
* User profiles

### 🏆 Leaderboards

* Rankings for every game
* Difficulty-based filtering
* Real-time updates

### 👨‍💼 Admin Panel

* User management
* Ban/Unban users
* System announcements
* Dashboard & statistics

---

## 🏗️ Tech Stack

### Mobile

* Flutter
* Dart
* Provider / Bloc
* Dio
* SharedPreferences
* Flutter Secure Storage

### Backend

* FastAPI
* Python 3.11
* SQLAlchemy
* PostgreSQL
* JWT Authentication
* OpenCV
* Kociemba Solver

### DevOps

* Docker & Docker Compose
* Git
* Postman

---

## 🚀 Getting Started

### Backend

```bash
git clone https://github.com/cuthanhcam/smart-games-solver.git
cd smart-games-solver

docker-compose up -d
```

Backend will be available at:

* API: `http://localhost:8000`
* Swagger Docs: `http://localhost:8000/docs`

### Mobile

```bash
cd mobile
flutter pub get
flutter run
```

---

## 📡 Main API Modules

* Authentication
* 2048
* Sudoku
* Gomoku
* Rubik Solver
* Leaderboards
* Social System
* Admin Panel

Interactive API documentation:

```
http://localhost:8000/docs
```

---

## 🧠 Algorithms

### Sudoku

* Backtracking puzzle generation
* Smart validation
* Hint system

### Gomoku AI

* Minimax
* Alpha-Beta Pruning
* Heuristic evaluation

### Rubik Solver

* OpenCV color detection
* Kociemba Two-Phase Algorithm

### 2048

* Matrix-based movement & merging logic

---

## 📂 Project Structure

```
smart-games-solver/
│
├── mobile/          # Flutter application
├── backend/         # FastAPI backend
├── docker-compose.yml
└── README.md
```

---

## 🧪 Testing

```bash
cd backend
pytest
```

---

## 🎯 Roadmap

* Improve AI performance
* Better Rubik color detection
* 3D Rubik visualization
* More puzzle games
* Enhanced social features
* Multiplayer support

---

## 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to your branch
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License**.

---

## 🙏 Acknowledgements

* Flutter
* FastAPI
* OpenCV
* Kociemba Algorithm

---

## 📧 Contact

* **GitHub:** https://github.com/cuthanhcam
* **Email:** [cuthanhcam04@gmail.com](mailto:cuthanhcam04@gmail.com)
