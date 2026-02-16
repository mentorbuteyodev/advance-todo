# Enterprise UI/UX Specification

This guide defines the aesthetic and interactive standards for the "TaskFlow" design system.

## 1. The Glassmorphic Formula (Aesthetics)

For a premium feel, avoid solid colors. Use depth and translucency.

### Card Recipe:

```dart
BoxDecoration(
  color: Colors.white.withAlpha(20), // Translucent fill
  borderRadius: BorderRadius.circular(24),
  border: Border.all(
    color: Colors.white.withAlpha(50), // Subtle inner stroke
    width: 1.5,
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withAlpha(20),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ],
)
```

## 2. Motion Physics (Interactivity)

Every interaction must have a physical response.

### Tap Feedback:

- All interactive items should scale on press (`ScaleTransition`) to `0.98`.
- Use `CurvedAnimation` with `Curves.easeOutQuart` for the snap-back.

### Navigational Flow:

- **Hero Tags**: Standardize tags for common elements (e.g., `user-avatar`, `task-title-[id]`).
- **Shared Axis**: Use `Animations` package for standard horizontal/vertical axis transitions.

## 3. Responsive Layout Protocol

Do not use hardcoded pixel values for layout.

- Use `LayoutBuilder` for adaptive widgets.
- Implement specialized "Compact" (Mobile) vs "Expanded" (Tablet) shells in `feature_shell` widgets.
- Always use a base `8px` spacing unit (`AppSpacing.sm = 8.0`).

## 4. Typography Hierarchy (Design Tokens)

Standardize text styles in `AppTheme`:

- **Display**: Reserved for headers (Inter-Bold).
- **Body**: High legibility (Roboto-Regular).
- **Caption**: Muted colors, tracking adjusted (+0.5).
