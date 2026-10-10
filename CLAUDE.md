# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DailyQuest is a Flutter workout tracker app inspired by the One Punch Man/Solo Leveling workout routine with anime-style progression rewards. The app tracks 100 push-ups, 100 sit-ups, 100 squats, and 10km run (broken into 100m increments) with stage-based progression and streak-based power-up animations.

## Documentation

Read these before starting work:
- `docs/adr/`: decisions already made. Don't relitigate an *Accepted* ADR. *Proposed* ADRs are implemented but await Wynand's confirmation. Record any new decision as the next numbered ADR, following ADR 0001.
- `docs/handoffs/`: numbered task briefs. Work from any handoff with `status: open` or `in-progress`. When the work ships, add an Outcome section and set `status: done`.
- `docs/spec.md`: the living product spec. Keep it in sync with behaviour changes.

## Development Commands

This is a Flutter project. Common commands include:

```bash
# Setup and dependencies
flutter doctor              # Check Flutter installation
flutter pub get             # Install dependencies
flutter pub upgrade         # Update dependencies

# Development
flutter run                 # Run on connected device/emulator
flutter run -d chrome       # Run web version in Chrome
flutter run --release       # Run optimized release build

# Building
flutter build web --release # Build for web deployment
flutter build apk          # Build Android APK
flutter build ios          # Build iOS app (macOS only)

# Testing and Quality
flutter test               # Run unit tests
flutter analyze           # Static analysis
dart format lib/          # Format Dart code
```

## Architecture Overview

The app follows Flutter clean architecture principles with the following planned structure:

### State Management
- **Riverpod**: Primary state management solution for reactive UI updates
- **SharedPreferences**: Local storage for workout progress and user settings

### Core Data Models
```dart
class WorkoutDay {
  DateTime date;
  int pushups, situps, squats, running; // running in 100m units
  bool runningEnabled, completed;
}

class UserProgress {
  int currentStreak, longestStreak, totalWorkouts;
  List<WorkoutDay> history;
}
```

### Key Features Architecture
- **Stage System**: Each exercise divided into 10 stages of 10 reps each
- **Daily Reset**: Automatic midnight counter reset functionality  
- **Animation System**: Power-up sequences based on consecutive day streaks
- **Running Toggle**: Optional inclusion of running in daily completion

### Screen Structure
1. **Main Workout Screen**: Primary interface with four exercise counter buttons
2. **Progress Screen**: Historical data and achievement tracking
3. **Settings Screen**: Workout preferences and customization

### Animation Specifications
Power-up sequences based on streak length:
- Days 1-7: Blue aura (basic power-up)
- Days 8-30: Yellow aura (Super Saiyan 1)
- Days 31-100: Electric effects (Super Saiyan 2) 
- Days 100+: Ultra Instinct sequence

## Web Deployment

The app is deployed via AWS Amplify with automatic CI/CD. The web version is available at: https://dailyquest.duhblinn.xyz

### Build Configuration
Uses `amplify.yml` for automated Flutter web builds with caching of `.pub-cache` and `.dart_tool` directories. Only `main` deploys ([ADR 0011](docs/adr/0011-deploy-main-only.md)). Keep the Flutter version in `amplify.yml` in step with local development, and download with `wget`, not `curl`.

## Development Phases

The project is structured in three phases:
1. **Core Functionality**: Basic UI, local storage, stage tracking
2. **Enhanced UX**: Progress history, streak tracking, basic animations
3. **Polish & Features**: Advanced animations, achievements, data export

## Key Design Principles

- **Anime-Inspired**: Visual design with power level color progression (blue → yellow → red)
- **Mobile-First**: Optimized for workout session usage with large touch targets
- **Gamification**: Stage completion and streak-based reward systems
- **Accessibility**: High contrast, screen reader support, haptic feedback