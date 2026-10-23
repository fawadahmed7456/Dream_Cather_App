# Project Structure & Core Analysis

This document provides a deep analysis of the architectural patterns and utility utilization in the `project structure example` folder.

## 🏗️ Architecture Overview

The project follows a modular, **Clean Architecture** approach with a clear separation between **Core** and **Feature** layers.

### 1. Core Layer (`lib/core`)
The `core` layer contains everything that is shared across multiple features. It is highly organized and modular.

| Component | Description |
| :--- | :--- |
| **`utils`** | Contains static helper classes like `Helpers` for date formatting, phone validation, and base64 conversion. It also includes `SizeUtils` for responsive design. |
| **`services`** | Uses a modular `part` / `part of` pattern. Includes `AuthService`, `NotificationService`, `HiveService` (storage), and `AnalyticsService`. |
| **`mixins`** | Standardizes behavior across repositories and cubits. The most notable is `ExceptionMixin`, which provides `handleFuture` for unified error handling and network checks. |
| **`di`** | Centralized Dependency Injection using `GetIt`. It's split into `core_injection.dart`, `datasource_injection.dart`, and `repository_injection.dart` for maintainability. |
| **`shared_widgets`** | A very rich library of 60+ reusable UI components (Buttons, TextFields, Charts, Indicators), ensuring UI/UX consistency. |
| **`theme`** | Centralizes `AppColor`, `Styles`, and `Assets` (generated or managed asset paths). |
| **`network`** | Contains specialized `NetworkClient` (built on Dio) with interceptors for logging and Sentry/Crashlytics integration. |

### 2. Feature Layer (`lib/feature`)
Features are structured following Clean Architecture principles, ensuring they are independent and testable.

*   **`data`**:
    *   `models`: JSON serialization/deserialization logic.
    *   `datasources`: Direct interaction with APIs (via `NetworkClient`).
    *   `repositories`: Implementation of domain repositories.
*   **`domain`**:
    *   `repositories`: Interfaces defining what data a feature needs.
    *   `entities`: Pure business logic objects.
*   **`presentation`**:
    *   `cubit`: State management using BLoC/Cubit.
    *   `pages`: The main UI screens.
    *   `widgets`: Component-specific UI elements.

## 🛠️ Utility Utilization Patterns

### Unified Error Handling
The project uses `Either<CustomException, T>` from the `dartz` package (or similar) to handle results.
*   **Repo Impl**: Uses `handleFuture(() async { ... })` from `ExceptionMixin`.
*   **Mixin**: Automatically checks connectivity, maps exceptions to `CustomException`, and logs to Crashlytics.

### Service Pattern
Services are registered as `LazySingleton` in `sl` (Service Locator). They often encapsulate 3rd party plugins (Firebase, Hive, Secure Storage) to provide a clean API to the rest of the app.

### Shared UI Components
The `shared_widgets` folder is a goldmine for UI consistency. Features should **always** try to use these before creating new widgets.

## ✨ Recommendations for the Project

To maintain this high standard in the rest of target features:
1.  **Register new features in DI**: Ensure new repositories and datasources are added to the appropriate `_injection.dart` files.
2.  **Use `ExceptionMixin`**: All repository implementations should mix in `ExceptionMixin` to benefit from standardized error handling.
3.  **Leverage Shared Widgets**: Before building a common UI element (like a button or modal), check `lib/core/shared_widgets`.
4.  **Modular Services**: If you add new global logic (e.g., location tracking), add it as a new service in `lib/core/services`.
