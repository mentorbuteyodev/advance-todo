# Flutter Production Templates

Use these templates to maintain high-fidelity standards across all project phases.

## 1. Modular Task Checklist (`task.md`)

```markdown
# [Project Name]

## Phase 0: Architecture & Core

- [ ] Implement Core Module abstractions (Theming, DI, Storage) <!-- id: 0.1 -->
- [ ] Design Auth-Data bridge & Sync Protocol <!-- id: 0.2 -->

## Phase 1: Feature: [Feature Name]

### Domain Layer

- [ ] Define Entity with immutability and copyWith <!-- id: 1.1 -->
- [ ] Create Repository interface & Failure objects <!-- id: 1.2 -->
- [ ] Design functional Use Cases <!-- id: 1.3 -->

### Data Layer

- [ ] Implement DTO with Mappers <!-- id: 1.4 -->
- [ ] Build Local & Remote DataSources <!-- id: 1.5 -->
- [ ] Realize RepositoryImpl with sync logic <!-- id: 1.6 -->

### Presentation Layer

- [ ] Develop Atomic Widgets & Design System alignment <!-- id: 1.7 -->
- [ ] Build BLoC/Cubit with state transitions <!-- id: 1.8 -->
- [ ] Implement Shell & Hero transitions <!-- id: 1.9 -->

## Phase 2: Production Hardening

- [ ] Coverage: Unit & Widget test suite <!-- id: 2.1 -->
- [ ] Verification: CI/CD integration and build checks <!-- id: 2.2 -->
```

## 2. Architecture Decision Record (ADR)

Use this template to document significant architectural pivots.

```markdown
# ADR [ID]: [Short Title]

## Status

[Proposed | Accepted | Superseded]

## Context

[What is the problem we are solving? What are the constraints?]

## Decision

[What is the chosen approach? Why was it selected?]

## Consequences

[What is the impact on the codebase? Any trade-offs?]
```

## 3. Implementation Plan Template (`implementation_plan.md`)

```markdown
# [Feature Name] Implementation

## User Review Required

> [!IMPORTANT]
> Detail any breaking changes or critical design decisions here.

## Proposed Changes

### [Feature] Component

#### [NEW] [file_name.dart](file:///path/to/file)

- Describe logic.

#### [MODIFY] [existing_file.dart](file:///path/to/file)

- Describe changes.

## Verification Plan

### Automated Tests

- `flutter test`

### Manual Verification

- Steps to verify in emulator.
```
