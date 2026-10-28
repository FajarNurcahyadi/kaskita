# KasKita Project Guide

## Overview

KasKita is a Flutter app for personal finance tracking. The inspected screens implement account registration and login, email OTP verification and password reset, a balance dashboard, and income/expense transaction entry and history. The UI text and currency formatting are primarily Indonesian. This workspace contains the Flutter client only; no backend implementation or database schema is present.

## Technology

- Dart with Flutter; the SDK constraint in `pubspec.yaml` is `>=3.3.0 <4.0.0`.
- Flutter Material 3 (`ThemeData(useMaterial3: true)`).
- `google_fonts` supplies Inter typography, `http` sends API requests, and `shared_preferences` persists the session token.
- `flutter_lints` is declared as a development dependency. Flutter's `flutter_test` SDK package is also declared, but no test files were found.
- Assets are configured from `assets/images/` in `pubspec.yaml`.

## Structure

```text
.
├── assets/images/                 # Declared image assets; currently empty in this checkout
├── lib/
│   ├── main.dart                  # App initialization, theme, navigator key, stack replacement helper
│   ├── core/
│   │   ├── api.dart               # Backend URL, auth/session persistence, HTTP API methods
│   │   ├── format.dart            # Rupiah/date formatting, date helpers, amount input formatter
│   │   └── theme.dart             # App colors, Inter text helper, ThemeData
│   ├── screens/                   # App screens and tab content
│   └── widgets/
│       ├── app_widgets.dart       # Shared buttons, fields, labels, feedback, social-logo row
│       ├── bottom_nav.dart        # Six-item bottom navigation UI
│       ├── design_frame.dart      # Fixed 393x852 Figma-coordinate layout helper
│       ├── otp_input.dart         # OTP entry control
│       └── tx_widgets.dart        # Transaction categories and reusable transaction row
├── download_assets.sh             # Downloads the referenced Figma-exported images
├── pubspec.yaml                  # SDK constraints, dependencies, and Flutter asset declaration
└── pubspec.lock                  # Resolved Dart package versions
```

Screen responsibilities:

- `splash_screen.dart` checks for a saved token, waits for the splash interval, and routes to `MainShell` or `WelcomeScreen`.
- `welcome_screen.dart`, `login_screen.dart`, and `signup_screen.dart` begin the unauthenticated flows.
- `verification_screen.dart`, `forgot_password_screen.dart`, `new_password_screen.dart`, `signup_success_screen.dart`, and `password_success_screen.dart` complete registration or password reset.
- `main_shell.dart` switches among six tabs. `dashboard_screen.dart`, `add_transaction_screen.dart`, and `history_screen.dart` implement the finance screens. `coming_soon_tab.dart` represents unfinished KasTarget, Community, and Profile tabs; Profile exposes logout.
- `home_placeholder.dart` is a legacy placeholder screen; the current entry flow in `main.dart` starts at `SplashScreen`.

Generated outputs and dependency metadata such as `build/`, `.dart_tool/`, and `.flutter-plugins-dependencies` are not source-of-truth project structure and should not be edited manually.

## Architecture And Data Flow

`main()` configures `Api.onUnauthorized`, then runs `KasKitaApp`, a `MaterialApp` with `buildTheme()` and `SplashScreen` as its home. Navigation is imperative with `Navigator` and `MaterialPageRoute`; `goReplaceAll` clears the route stack when changing the app's top-level flow. There is no named-route table or third-party routing package.

Screens own their transient form, loading, and fetched-data state through `StatefulWidget` and `setState`. Shared UI and formatting logic live under `lib/widgets/` and `lib/core/`. There is no app-wide state-management package or separate model/repository layer in this checkout; API response data is generally consumed as `Map<String, dynamic>` and lists.

`Api` in `lib/core/api.dart` is the client boundary. It uses JSON over `package:http/http.dart` and exposes:

- Unauthenticated auth endpoints under `/auth/`: register, login, registration OTP, reset OTP, resend OTP, forgot password, and reset password.
- Authenticated finance endpoints: `GET /dashboard?today=...`, `GET /transactions?month=...&type=...`, `POST /transactions`, and `DELETE /transactions/{id}`.
- Successful login and registration verification store a `token` in `SharedPreferences`. Authenticated calls attach it as `Authorization: Bearer ...`. A 401 clears the token and invokes the callback configured in `main.dart`, which returns to Welcome.
- `_post` and `_authed` translate HTTP failures and connection errors to `ApiException`; screens show these via the shared snackbar helpers.

`Api.baseUrl` uses compile-time `--dart-define=API_URL=...` when provided; otherwise it selects `http://10.0.2.2:3000` for Android and `http://localhost:3000` for iOS simulator/web. The backend must implement the endpoint and response shapes consumed by the screens. There is no database connection in the Flutter client.

## Conventions And Safe Changes

- Keep screens in `lib/screens/`, shared presentation widgets in `lib/widgets/`, and shared API/theme/format logic in `lib/core/`.
- Follow Dart naming: `UpperCamelCase` for types, `lowerCamelCase` for members/functions, and a leading underscore for private declarations.
- Prefer existing shared controls (`PrimaryButton`, `AppField`, `TxTile`) and helpers (`Api`, `rupiah`, `isoDate`, `showError`, `showInfo`) over parallel implementations.
- Preserve the existing direct `Navigator` flow and screen-local state unless a task explicitly calls for an architecture change.
- Check API request fields and response keys in the relevant screen and `Api` method together. Backend code is not available here to independently confirm the contract.
- Do not commit generated build output or edit generated Flutter files. Keep secrets out of documentation and source; configure deployment-specific API URLs outside hard-coded source where possible.
- `download_assets.sh` uses temporary Figma asset URLs, which its own comments say may expire. Inspect any downloaded assets before relying on them.

## Setup And Verification

The following is based on the checked-in Flutter manifest and the analyzer command run in this workspace:

```sh
flutter pub get
flutter analyze
```

For a configured Flutter target and available backend, run with an API override as needed:

```sh
flutter run --dart-define=API_URL=<backend-url>
```

The current checkout has no `android/`, `ios/`, or source `web/` platform directory, so an actual run/build target cannot be confirmed from this workspace. No test files were found; add tests before relying on a `flutter test` result. The observed `flutter analyze` run completed with four informational `prefer_const_constructors` notices in `lib/screens/dashboard_screen.dart` and no reported errors.

## Known Limitations And Unverified Areas

- `assets/images/` is empty, although the manifest declares it and screens reference logo, social, and illustration image files. `build/` contains generated outputs, but those do not verify that source assets are present. The UI can fail to load those images until the assets are restored.
- KasTarget, Community, and Profile are placeholder tabs; the dashboard's Analis action is informational only. The social provider row displays image assets but this code does not implement provider sign-in.
- The backend, API response schemas, persistence/database implementation, and server startup instructions are not in this workspace. The API URL comments refer to a separately running backend.
- No environment files, platform project directories, automated test files, or other project documentation were found during inspection. Platform build commands and backend integration could not be verified.
- Authenticated `_authed` requests do not set the explicit 15-second timeout used by `_post`; investigate before changing request behavior.