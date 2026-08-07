# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Commands

```bash
# From superup/ root directory:
melos bs                           # Bootstrap all packages
melos run g_app                    # Generate Chopper API code (after modifying *_api.dart)
melos run analyze                  # Static analysis across all packages
melos run build_android            # Build Android APK (--split-per-abi)
melos run build_web                # Build web version

# Quick validation (preferred over full builds):
flutter analyze                    # Fast code check without building
```

## App Architecture

### Entry Points

- `lib/main.dart` - Production entry (AppEnvironment.prod)
- `lib/main_local.dart` - Local development entry (AppEnvironment.local)

### Directory Structure

```
lib/
├── app/
│   ├── core/                      # Shared app infrastructure
│   │   ├── api_service/           # Chopper HTTP clients
│   │   │   ├── auth/              # AuthApi - login, register, logout
│   │   │   ├── profile/           # ProfileApi - user profiles
│   │   │   └── story/             # StoryApi - stories CRUD
│   │   ├── app/                   # AppFactory - MaterialApp creation
│   │   ├── app_nav/               # AppNavigation - wide/mobile routing
│   │   ├── controllers/           # Global controllers
│   │   ├── initialization/        # AppInitializer - startup sequence
│   │   ├── models/                # Shared data models
│   │   └── widgets/               # Reusable widgets
│   └── modules/                   # Feature modules
│       ├── auth/                  # Login, register, password reset
│       ├── home/                  # Main app shell
│       │   ├── home_controller/   # HomeView with bottom tabs
│       │   ├── mobile/            # Mobile-specific tabs (rooms, story, calls, users, settings)
│       │   ├── home_wide_modules/ # Desktop/tablet wide layouts
│       │   └── settings_modules/  # Settings subpages
│       ├── chat_settings/         # Room settings (single, group, broadcast)
│       ├── story/                 # Story creation (text, media)
│       └── peer_profile/          # User profile views
└── v_chat_v2/
    ├── v_chat_config.dart         # VChat SDK initialization
    └── translations.dart          # VChat localization bridges
```

### Module Pattern

Each feature module follows this structure:

```
module_name/
├── controllers/       # Business logic (extends SLoadingController or ValueNotifier)
├── states/            # Immutable state classes
├── views/             # StatefulWidgets with controller lifecycle
├── widgets/           # Module-specific widgets
└── mobile/            # Mobile-only components (sheets, dialogs)
```

### State Management Pattern

Controllers extend either:

- `SLoadingController<T>` - For async data loading with loading/error/success states
- `ValueNotifier<T>` - For simpler reactive state

Views use:

- `ValueListenableBuilder` to rebuild on state changes
- Controller instantiated in `initState()`, disposed in `dispose()`

### Dependency Injection

GetIt singletons registered in `lib/app/core/utils/lazy_injection.dart`:

- `AuthApiService`, `ProfileApiService`, `StoryApiService`
- `VAppConfigController`, `VersionCheckerController`
- `AppSizeHelper` - Responsive layout helper

### Navigation System

`AppNavigation.toPage()` handles both mobile and desktop:

- Mobile: Standard Navigator push
- Wide (desktop/tablet): Routes to specific Navigator keys (rooms, messages, chat info)

Navigation types:

- `AppNavigationType.chatRoom` - Wide rooms panel
- `AppNavigationType.messages` - Wide messages panel
- `AppNavigationType.chatInfo` - Wide info sidebar
- `AppNavigationType.popUpAlert` - Modal dialogs

### API Layer (Chopper)

API files in `core/api_service/`:

1. `*_api.dart` - Chopper service definition with annotations
2. `*_api.chopper.dart` - Generated code (run `melos run g_app`)
3. `*_api_service.dart` - Service wrapper exposing typed methods

After modifying `*_api.dart` files, regenerate with:

```bash
melos run g_app
```

### VChat Integration

Initialized in `v_chat_v2/v_chat_config.dart`:

- Configures navigation callbacks for messages, rooms, settings
- Sets up FCM push notifications
- Integrates with `AppNavigation` for wide layout support
- Call permissions conditional on `VPlatforms.isMobile`

### Platform Handling

`AppInitializer.initialize()` handles:

- Firebase init (mobile, macOS, web only)
- Desktop window setup via window_manager
- Web URL strategy (path-based)
- Call services (Android foreground service, iOS CallKit)

## Key Files to Modify

| Task                 | File                                              |
|----------------------|---------------------------------------------------|
| Add API endpoint     | `core/api_service/{domain}/{domain}_api.dart`     |
| Add new feature      | Create module in `modules/` following pattern     |
| Modify chat behavior | `v_chat_v2/v_chat_config.dart`                    |
| Add translations     | `packages/s_translation/`                         |
| Modify constants     | `packages/super_up_core/lib/src/s_constants.dart` |

## Environment Configuration

- Production URL: `SConstants.productionBaseUrl`
- Local URL: `SConstants.localBaseUrl`
- Switch via `AppEnvironment` enum passed to `AppInitializer.initialize()`
