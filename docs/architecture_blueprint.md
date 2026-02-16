# System Architecture Blueprint

## 1. High-Level Architecture

We will use **Clean Architecture** combined with **Feature-First** modularization. This ensures scalability, testability, and maintainability.

### Layers

1. **Presentation Layer**: UI (Widgets) and State Management (Bloc/Cubit).
2. **Domain Layer**: Pure Dart logic. Entities, UseCases, and Repository Interfaces.
3. **Data Layer**: Data retrieval and storage. Models, Data Sources (Local/Remote), and Repository Implementations.

## 2. Tech Stack

- **Framework**: Flutter (Latest Stable)
- **Language**: Dart
- **State Management**: flutter_bloc
- **Dependency Injection**: get_it + injectable
- **Navigation**: go_router
- **Local Database**: Isar (High performance, ACID compliant)
- **Remote Database**: Supabase (PostgreSQL, Realtime, Auth) - _Planned for Milestone 2_
- **Localization**: easy_localization
- **Code Generation**: build_runner, freezed, json_serializable

## 3. Data Flow

`UI` -> `Bloc` -> `UseCase` -> `Repository` -> `DataSource` -> `Database/API`

## 4. Folder Structure (Feature-First)

```
lib/
├── core/                   # Shared logic, extensions, constants, error handling
│   ├── basic_usecase/
│   ├── config/
│   ├── constants/
│   ├── error/
│   ├── utils/
│   └── widgets/            # Generic shared widgets (Button, Input, etc.)
├── features/
│   ├── tasks/              # Feature: Task Management
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       └── widgets/
│   └── settings/           # Feature: Settings
├── main.dart
└── injection.dart          # DI Setup
```

## 5. Scalability Strategy

- **Modularization**: Features can be extracted into separate packages if needed.
- **Strict Boundaries**: Domain layer knows nothing about Flutter or Data layer.
- **Asynchronous**: All I/O operations must be async (Future/Stream).
