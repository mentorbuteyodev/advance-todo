---
name: Flutter Production Workflow
description: A high-fidelity, multi-phase workflow for building production-ready Flutter applications with Clean Architecture, Offline-First Sync, and Premium UX.
---

# Flutter Production Workflow

This skill encapsulates the standards and repeatable processes for creating "World-Class" Flutter applications. It is designed to be used by an AI agent in a multi-phase lifecycle: **Planning → Execution → Verification**.

## 1. Architectural Standards (Clean Architecture)

Always structure the project using **Feature-First Clean Architecture**.

### Layer Definitions:

- **Domain Layer**: The heart of the app. Pure Dart. Contains Entities (plain objects), Repositories (interfaces), and Use Cases.
- **Data Layer**: Implementation detail. Contains Models (serialized entities), Data Sources (Remote/Local), and Repository implementations.
- **Presentation Layer**: UI and Logic. Contains Pages, Widgets, and Blocs/Cubits.

### Key Rules:

- The **Domain** layer must never import from **Data** or **Presentation**.
- Use **GetIt** for Dependency Injection to decouple implementations from usage.
- Use **BLoC/Cubit** for all state management; never use `setState` for business logic.

---

## 2. High-Fidelity UI/UX Patterns

A production app must _feel_ premium. Use these specific UI techniques:

### Visual Aesthetics:

- **Glassmorphism**: Use `white.withAlpha(x)` with subtle gradients and `PhysicalModel` for shadows.
- **Hero Animations**: Use them for all navigational transitions (e.g., Avatar to Profile).
- **Staggered Animations**: Use `flutter_staggered_animations` for list loads.
- **Pinned Headers**: Use `ValueListenableBuilder` tied to a `ScrollController` to animate header height and opacity on scroll.

### Micro-interactions:

- Animated search-bar swaps using `AnimatedSwitcher`.
- Scaled list items on tap to provide tactile feedback.
- Custom empty states with themed icons and messaging.

---

## 3. Reliable Offline-First Sync

Do not rely on simple Firestore listeners. Implement a robust bidirectional bridge:

### Sync Strategy:

- **Local Source**: Use **Hive** (or similar) as the primary source of truth.
- **Pending Flags**: Tasks created offline must have `pendingSync: true`.
- **Soft Deletes**: Never delete data locally; use `isDeleted: true` to ensure the deletion propagates to the cloud.
- **Last-Write-Wins**: Use `updatedAt` timestamps on both local and remote nodes to resolve conflicts automatically.
- **Auth Bridging**: Automatically trigger a `syncNow()` on login and clear local Hive data on logout.

---

## 4. Production Hardening

An app is not "production-ready" until it is stable and measurable.

### Error Handling:

- Wrap your app in `runZonedGuarded` in `main.dart`.
- Set up `FlutterError.onError` to catch framework-level crashes.
- Always include `try-catch` blocks around external services (Firebase, Hive, Notifications) to prevent boot-loops.

### CI/CD & Testing:

- Maintain a GitHub Action that runs `flutter analyze` and `flutter test` on every push.
- **Unit Testing**: Mock dependencies (Repositories, Cubits) using `mocktail` or `mockito`.
- **Integration Testing**: Implement at least one "Happy Path" E2E test using `integration_test`.

---

## 5. The Multi-Agent Workflow

Follow this cycle for every significant change:

1.  **Planning**: Research the codebase, update `task.md`, and create an `implementation_plan.md`. Get user approval.
2.  **Execution**: Implement changes layer-by-layer (Domain → Data → Presentation). Run `flutter analyze` frequently.
3.  **Verification**: Conduct manual testing (terminal logs) and automated testing. Create a `walkthrough.md` with proof of work.
