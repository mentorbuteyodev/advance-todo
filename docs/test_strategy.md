# QA Strategy & Test Plan

## 1. Testing Pyramid

We adhere to the standard testing pyramid:

- **Unit Tests (70%)**: Fast, isolated tests for logic.
  - Entities, UseCases, Repositories (Mocked), Bloc/Cubit states.
- **Widget Tests (20%)**: UI component tests.
  - Verifying widget rendering, tap interactions, and simple state changes.
- **Integration Tests (10%)**: End-to-end flows.
  - Full app flows (Create Task -> Verify in List).

## 2. Tools & Frameworks

- **Unit/Widget**: `flutter_test`, `bloc_test`, `mocktail` (for mocking).
- **Integration**: `integration_test` (part of Flutter SDK).
- **Code Coverage**: `lcov` (aiming for > 90%).

## 3. Test Cases (Milestone 1)

| ID    | Type        | Description                    | Expected Result                             |
| ----- | ----------- | ------------------------------ | ------------------------------------------- |
| TC-01 | Unit        | Create valid task entity       | Entity created with correct ID and defaults |
| TC-02 | Unit        | TaskRepository.save()          | Data source called with correct model       |
| TC-03 | Widget      | Task Item renders correctly    | Checkbox and title are visible              |
| TC-04 | Widget      | Tapping checkbox toggles state | UI reflects new state                       |
| TC-05 | Integration | Full Task Creation Flow        | Task appears in list after adding           |

## 4. CI/CD Integration

- Tests run on every Pull Request.
- Block merge if tests fail or coverage drops below threshold.
