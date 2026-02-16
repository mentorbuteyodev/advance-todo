# UX/UI Design Plan

## 1. Design Philosophy

- **Minimalist & Content-First**: Focus on the tasks, not the UI chrome.
- **Micro-Interactions**: Subtle animations for checking off tasks, deleting, and reordering.
- **Accessibility**: High contrast, screen reader support, large touch targets.

## 2. Design System

- **Typography**: `Inter` or `Roboto` (Google Fonts).
  - H1: 32px Bold
  - H2: 24px SemiBold
  - Body: 16px Regular
  - Caption: 12px Medium
- **Color Palette**:
  - Primary: #6200EE (Deep Purple) - Focus & Action
  - Secondary: #03DAC6 (Teal) - Success & Accents
  - Background: #F5F5F5 (Light Gray) / #121212 (Dark Mode)
  - Surface: #FFFFFF (White) / #1E1E1E (Dark Grey)
  - Error: #B00020
- **Spacing**: 8px grid system (4px, 8px, 16px, 24px, 32px, 48px).

## 3. Component Hierarchy

- **Atoms**: Buttons, Inputs, Icons, Checkboxes, Chips.
- **Molecules**: Task Item (Checkbox + Text + Due Date), Search Bar, Filter Tabs.
- **Organisms**: Task List, Add Task Modal, Settings Panel.
- **Templates**: Home Screen, Task Detail Screen.

## 4. User Flows

### Creating a Task

1. User taps FAB (+).
2. Bottom Sheet appears with keyboard focus.
3. User types task title.
4. (Optional) User adds date/tag.
5. User taps "Save" or hits Enter.
6. Sheet closes, task animates into the list.

### Completing a Task

1. User taps checkbox.
2. Checkbox animates to checked state.
3. Task text strikes through and dims.
4. Task moves to "Completed" section (optional) or stays with strikethrough.
