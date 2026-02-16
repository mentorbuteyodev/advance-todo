# Flutter Production Templates

Use these templates to maintain high-fidelity standards across all project phases.

## 1. Task Checklist Template (`task.md`)

```markdown
# Project Name

## Milestone 1: Foundation

- [ ] Initialize Clean Architecture Folders <!-- id: 1.1 -->
- [ ] Configure Dependency Injection (GetIt) <!-- id: 1.2 -->
- [ ] Set up GoRouter with Auth Guard <!-- id: 1.3 -->

## Milestone 2: Feature Development

- [ ] Domain: Define Entities & Repositories <!-- id: 2.1 -->
- [ ] Data: Implement Models & DataSources <!-- id: 2.2 -->
- [ ] Presentation: Build UI & Blocs <!-- id: 2.3 -->

## Milestone 3: Production Readiness

- [ ] Implement global error handling (ZonedGuarded) <!-- id: 3.1 -->
- [ ] Set up CI/CD pipeline (GitHub Actions) <!-- id: 3.2 -->
- [ ] Verify unit and integration tests <!-- id: 3.3 -->
```

## 2. Implementation Plan Template (`implementation_plan.md`)

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
