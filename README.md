<p align="center">
  <img src="android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png" width="80" alt="TaskFlow Logo"/>
</p>

<h1 align="center">TaskFlow</h1>

<p align="center">
  <strong>A beautifully crafted, intelligent task management app built with Flutter</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey" alt="Platform"/>
</p>

---

## ✨ Overview

**TaskFlow** is a modern, feature-rich task management application designed for both casual users and power users. Built with **Clean Architecture** principles and **BLoC** state management, it delivers a premium, responsive experience with smooth animations, intelligent notifications, and hierarchical subtask management.

---

## 🚀 Features

### Core Task Management

- **Full CRUD** — Create, read, update, and delete tasks with ease
- **Inline Editing** — Tap any field on the detail page to edit in-place
- **Priority Levels** — Low, Medium, High, and Urgent with color-coded indicators
- **Due Dates & Times** — Set precise deadlines with date + time picker
- **Tags** — Add, remove, and organize tasks with custom tags
- **Smart Filters** — Instantly filter by All Tasks, Today, Upcoming, or Completed

### Subtask Management

- **Hierarchical Tasks** — Break tasks into manageable subtasks
- **Progress Tracking** — Visual progress bar shows subtask completion
- **Toggle & Delete** — Complete or remove subtasks with a single tap

### Notifications & Reminders

- **Instant Confirmation** — Get notified when a reminder is set
- **30-Minute Warning** — Heads-up notification before a task is due
- **Due Time Alert** — Notification fires at the exact due time
- **Works Offline** — Notifications fire even when the app is closed

### Design & UX

- **Premium UI** — Gradient app bars, smooth animations, dynamic colors
- **Dark Mode** — Full dark theme support via system preference
- **Auto-scroll Filters** — Filter tabs auto-center when selected
- **Swipe Actions** — Slide to delete tasks from the list
- **Responsive Layout** — Adapts to any screen size

---

## 🏗️ Architecture

TaskFlow follows **Clean Architecture** with a clear separation of concerns:

```
lib/
├── core/                   # Shared utilities & config
│   ├── config/             # Router, app configuration
│   ├── constants/          # App-wide constants
│   ├── error/              # Error handling
│   ├── services/           # Notification service
│   ├── theme/              # Light & dark themes
│   └── usecase/            # Base use case interface
├── features/
│   └── tasks/
│       ├── domain/         # Entities, repository interfaces
│       ├── data/           # Models, data sources, implementations
│       └── presentation/   # BLoC, pages, widgets
├── injection.dart          # Dependency injection (GetIt)
└── main.dart               # App entry point
```

### Tech Stack

| Layer                | Technology                  |
| -------------------- | --------------------------- |
| **UI**               | Flutter (Material 3)        |
| **State Management** | flutter_bloc                |
| **Navigation**       | go_router                   |
| **Local Storage**    | Hive CE                     |
| **Notifications**    | flutter_local_notifications |
| **DI**               | get_it                      |
| **Fonts**            | Google Fonts                |

---

## 📦 Getting Started

### Prerequisites

- Flutter SDK 3.x+
- Dart 3.x+
- Android Studio / VS Code
- Android emulator or physical device

### Installation

```bash
# Clone the repository
git clone https://github.com/mentorbuteyodev/advance-todo.git

# Navigate to the project
cd advance-todo

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Running Tests

```bash
# Static analysis
dart analyze

# Unit tests
flutter test
```

---

## 🗺️ Roadmap

### ✅ Milestone 1: Core Foundation (Complete)

- [x] Task CRUD with inline editing
- [x] Subtasks with progress tracking
- [x] Tags & categories
- [x] Due dates & smart reminders
- [x] Priority levels (Low → Urgent)
- [x] Offline support (Hive local DB)
- [x] Premium UI with dark mode

### ✅ Milestone 2: Connectivity & Advanced Features (Complete)

- [x] User authentication (Email, Social)
- [x] Real-time sync across devices
- [x] Recurring tasks (Daily, Weekly, Custom)
- [x] Focus Mode (Pomodoro timer)

### ✅ Milestone 3: AI & Intelligence (Complete)

- [x] Natural language input ("Buy milk tomorrow at 5pm")
- [x] Smart task prioritization
- [x] Productivity insights & analytics

---

## 👨‍💻 Developer

**Mentor Buteyo**

- GitHub: [@mentorbuteyodev](https://github.com/mentorbuteyodev)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Built with ❤️ using Flutter
</p>
