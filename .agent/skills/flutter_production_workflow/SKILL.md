---
name: Flutter Production Workflow (Enterprise Grade)
description: A high-fidelity, industrial-strength workflow for building production-ready Flutter applications with Modular Clean Architecture, Offline-First Delta-Sync, and Multi-Agent Orchestration.
---

# Flutter Production Workflow (Enterprise)

This skill defines the "Gold Standard" for mission-critical Flutter applications. It is designed for multi-agent systems to execute complex, high-reliability development cycles.

## 1. Modular Clean Architecture (MCA)

Traditional Clean Architecture is not enough for large projects. We enforce **Modular Clean Architecture**.

### Structural Breakdown:

- **Core Module**: Cross-cutting concerns (Theming, Networking, DI, Storage).
- **Feature Modules**: Independent vertical slices (e.g., `feature_auth`, `feature_tasks`).
- **Domain (Feature Level)**:
  - `Entities`: Thread-safe, immutable data objects.
  - `Use Cases`: Single-responsibility business logic units.
  - `Failures`: Standardized error objects for the domain.
- **Data (Feature Level)**:
  - `DTOs / Models`: Serialization layers with `fromJson/toJson`.
  - `RepositoriesImpl`: The bridge between remote/local sources.
  - `Mappers`: Pure functions converting DTOs to Entities.
- **Presentation (Feature Level)**:
  - `Atomic Widgets`: Small, reusable UI components.
  - `Feature Shell`: The entry point for the feature.
  - `Blocs/Cubits`: Reactive state management with custom `Transition` tracking.

### The "Dependency Rule":

Inner layers (Domain) **NEVER** know about outer layers (Data/Presentation). All external dependencies are injected via interfaces.

---

## 2. Multi-Agent Orchestration Protocol (MAOP)

When working as a team or across multiple tool-turns, agents must follow this strict state machine:

### Phase A: The Architect (Planning)

1.  **Codebase Audit**: Scan existing abstractions to avoid duplication.
2.  **Schema Definition**: Define JSON/Database schemas before writing code.
3.  **Implementation Plan**: Mandatory `implementation_plan.md` with file-level diff predictions.
4.  **UI Mockup**: Use `generate_image` for new screens to align aesthetics.

### Phase B: The Builder (Execution)

1.  **Contract First**: Implement Domain interfaces first.
2.  **Surgical Edits**: Use `multi_replace_file_content` to keep files clean.
3.  **Local First**: Build local persistence before remote APIs.
4.  **Lint-as-you-go**: Run `flutter analyze` after every major file change.

### Phase C: The QA / Hardening (Verification)

1.  **Unit Tests**: Minimum 80% coverage for BLoCs and Use Cases.
2.  **Widget Tests**: Verify state-to-UI mapping.
3.  **Integration Tests**: Run the "Gold Path" E2E.
4.  **Proof of Work**: Cumulative `walkthrough.md` with recordings/logs.

---

## 3. High-Fidelity UX & Design Systems

Production apps must be "Market-Ready" from day one.

### UX Requirements:

- **Design Tokens**: Centralized HSL colors, Spacing (4px grid), and Typography in `AppTheme`.
- **Motion Spec**:
  - `Micro-animations`: Scale-on-tap, Fade-on-load.
  - `Structural Motion`: Hero transitions for navigation, Staggered lists.
  - `Scroll-Dynamics`: Pinned/Shrinking headers via `NestedScrollView` or `CustomScrollView`.
- **Accessibility**: Semantic labels for all interactive elements.

---

## 4. Advanced Offline-First Sync (Delta-Sync)

A production sync engine must handle low-bandwidth and high-conflict scenarios.

### Logic Flow:

1.  **Optimistic UI**: Update local DB (Hive) and UI immediately.
2.  **The Outbox Pattern**: Store pending operations in a persistent local queue.
3.  **Delta Syncing**: Only upload modified fields, not the whole object.
4.  **Conflict Strategy**:
    - Meta-data: `updatedAt` (Server-side & Client-side).
    - Logic: "Last Write Wins" or "Merge" (based on specific field type).
5.  **Soft-Delete Protocol**: Mark `deleted_at`, sync to cloud, then hard-delete locally only after cloud confirmation.

---

## 5. Security & Stability Core

- **Secure Storage**: Use `flutter_secure_storage` for tokens and sensitive keys.
- **Environment Management**: Separation of `Dev`, `Staging`, and `Prod` flavors.
- **Global Guardians**:
  - `runZonedGuarded` for unhandled exceptions.
  - `FlutterError.onError` for rendering crashes.
  - `PlatformDispatcher` for native-level crashes.
- **CI Enforcement**: Reject any push that fails `lint` or `test` cycles.
