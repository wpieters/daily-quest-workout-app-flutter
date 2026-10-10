# Solo Leveling Workout Tracker - Specification

## Overview
A Flutter mobile app that tracks daily workout progress for the One Punch Man/Solo Leveling workout routine with staged progression and animated rewards.

## Core Features

### Workout Tracking
- **Daily Reset**: App resets counters at midnight
- **Four Exercise Types**:
  - Push-ups (1 rep per tap, target: 100)
  - Sit-ups (1 rep per tap, target: 100) 
  - Squats (1 rep per tap, target: 100)
  - Running (100m per tap, target: 10km = 100 taps)

### User Interface
- **Main Screen**: A "QUEST INFO" system window (goals, penalty caution, streak) above four exercise panels in a grid
- **Counter Display**: Bracketed monospace counts, e.g. `[42 / 100]`, `[3.2KM / 10KM]`
- **Undo**: Each exercise panel has a minus button to undo a mis-tap. XP already earned is kept; reaching the target again does not re-award it or replay the celebration
- **Progress Bars**: Visual progress indication for each exercise
- **Running Toggle**: Checkbox to enable/disable running from daily completion. When unchecked, the running button is disabled (greyed out and non-interactive)
- **Level Header**: Level, title and XP bar, with floating "+XP" feedback on each award; tap to open the character sheet
- **Stage Completion**: Visual indicator showing completed "stages" (every 10 reps/taps)

### Progression System
- **Stages**: Each exercise divided into 10 stages of 10 reps each
- **Stage Visualization**: Progress rings or bars showing 10 stages per exercise
- **Daily Completion**: All enabled exercises must reach 100 to complete the day

### RPG Progression (XP, Levels, Titles, Stats)

All tunable numbers live in `lib/progression/progression_config.dart`. The rules
engine (`lib/progression/`) is pure Dart with no Flutter imports.

#### XP
- 100 XP when an individual exercise reaches its target (not per rep)
- +100 bonus XP when all four are completed (requires running enabled)
- Full day = 500 XP; day without running = 300 XP
- XP awards for a day never repeat or get revoked (resetting today's counters or toggling running does not change XP already earned)
- Missed day = -150 XP

#### Missed Days and Level Protection
- A **missed day** is a past day on which no exercise reached its target. Partial days are not penalised *(proposed default)*
- There is no backend: on app open (and at midnight while open) every day since `lastActiveDate` is settled retroactively, exactly once *(proposed default)*
- While consecutive misses are fewer than 7, XP is clamped at the current level's floor; penalties are not banked. From the 7th consecutive miss on, deductions can cross level boundaries *(proposed default)*

#### Leveling Curve
- XP from level L to L+1 = `round(100 + 18·L + 2.5·L^1.35)`, levels 1–100
- Total to level 100 ≈ 152k: ~10 months at 500/day, ~a year at ~440/day, ~17 months at 300/day

#### Titles (derived from level, never stored; drop with level)
| Level | Title |
|---|---|
| 1 | World's Weakest |
| 10 | Fledgling Warrior |
| 20 | E-Rank Hunter |
| 30 | D-Rank Hunter |
| 40 | C-Rank Hunter |
| 50 | B-Rank Hunter |
| 60 | A-Rank Hunter |
| 70 | National Level Hunter |
| 80 | Shadow Sovereign Candidate |
| 90 | S-Rank Hunter |
| 100 | World's Strongest Hunter |

#### Stats
- HP, MP, Strength, Vitality, Agility, Intelligence, Perception, Fatigue
- Strength ← push-ups, Vitality ← sit-ups, Agility ← squats. Growth is level-based, not rep-based
- Intelligence and Perception only grow through skills and items (future), never per level
- Start at 10 each *(proposed default)*; hard cap 255
- On level-up: +2 to STR/VIT/AGI if that exercise was completed on ≥50% of the days spent in the previous level (the level-up day counts with what's done so far) *(proposed default)*. ~210 max by level 100
- On level-down: -5 STR/VIT/AGI per level lost, floor 10 *(proposed default)*
- HP = Vitality × 10, MP = Intelligence × 5 (derived, not stored) *(proposed default)*
- 3 skill points per level, granted only the first time a level is reached. Stored for the future skill store; not removed on level-down

#### Fatigue
- Start at 7, recover 1 per day up to max
- Max +1 per 10 levels, only if running was completed on ≥50% of days in that span (max 17). Each milestone is awarded at most once *(proposed default)*
- Spent in multiplayer battles (future); currently only current and max are tracked

#### Ceremonies
- Level-up: full-screen Solo Leveling "system window" with the level change, stat gains, skill points and fatigue gains; tap to dismiss. Multiple level-ups queue
- Title unlock: shown in the same window as "TITLE ACQUIRED"
- Animations are placeholders until final assets exist

### Reward System
- **Completion Animation**: Goku power-up style GIF sequence when daily goal achieved
- **Power Level Progression**: Different animations based on consecutive days completed
- **Achievement Tracking**: Store consecutive days, total workouts, personal records

## Technical Requirements

### Flutter Architecture
- **State Management**: Provider or Riverpod for reactive state
- **Local Storage**: SharedPreferences for daily progress and streak data
- **Animation System**: Flutter's built-in animation widgets + GIF support

### Data Models
```dart
class WorkoutDay {
  DateTime date;
  int pushups;
  int situps; 
  int squats;
  int running; // in 100m units
  bool runningEnabled;
  bool completed;
  int xpEarned;       // XP already awarded for this day
  bool bonusAwarded;
}

class UserProgress {
  int currentStreak;
  int longestStreak;
  int totalWorkouts;
  List<WorkoutDay> history;       // every day with activity
  ProgressionState progression;
}

class ProgressionState {
  int totalXp, skillPoints, fatigueCurrent, fatigueMax, consecutiveMissedDays;
  DateTime? lastActiveDate;       // last day whose missed-day processing is settled
  CharacterStats stats;           // STR, VIT, AGI, INT, PER
  DayTally levelTally;            // per-exercise completion days at current level
  DayTally fatigueTally;          // running days since last fatigue milestone
  int highestLevel, fatigueMilestoneLevel;
}
// Derived, never persisted: level, XP into level, title, HP, MP
```

Stored data carries `schemaVersion` (currently 2). Data from before the
progression system (no `schemaVersion`) keeps its history and streaks and starts
progression at starting values with no retroactive penalties; today's progress,
if any, is awarded XP on first load.

### Core Screens
1. **Main Workout Screen**: Primary interface with exercise buttons and level header
1. **Character Sheet**: Level, title, XP, HP/MP, fatigue, stats and unspent skill points
2. **Progress Screen**: Historical data and achievements
3. **Settings Screen**: Preferences and workout customization

## User Experience Flow

### Daily Workflow
1. User opens app to main workout screen
2. Tap exercise buttons to increment counters
3. Visual feedback shows stage completion (every 10 reps)
4. Running can be toggled on/off for daily completion
5. Each exercise reaching 100 awards XP; level-ups show the system window
6. When all enabled exercises reach 100, trigger celebration animation
7. Progress saves automatically

### Visual Design
- **Color Scheme**: Dark-only Solo Leveling "system window" look: navy background `#0F131A`, panels `#151C28`, cyan accent `#00AAFF` with 30% borders; green/orange/red for complete/warning/danger. Power level colors (blue → yellow → red) for streak tiers
- **Labels**: Uppercase with wide letter spacing
- **Glow**: Pulsing cyan glow on system windows (level-up, completed quest panel); expanding power-up ring on each tap. Static when reduced motion is requested
- **Typography**: Bold, easy-to-read monospace numbers for counters
- **Animations**: Smooth counter increments, stage completion effects
- **Accessibility**: Large touch targets, high contrast, screen reader support

## Animation Specifications

### Power-Up Sequences
Based on consecutive day streak:
- **Days 1-7**: Basic power-up (blue aura)
- **Days 8-30**: Super Saiyan 1 (yellow aura) 
- **Days 31-100**: Super Saiyan 2 (electric effects)
- **Days 100+**: Ultra Instinct or custom sequence

### Micro-Animations
- Button press feedback with scale animation
- Counter increment with number flip animation
- Stage completion with ring fill or explosion effect
- Progress bar smooth transitions

## Development Phases

### Phase 1: Core Functionality
- Basic UI with four counter buttons
- Local storage for daily progress
- Stage tracking and visual indicators
- Running toggle functionality

### Phase 2: Enhanced UX
- Progress history screen
- Streak tracking system
- Basic completion animation
- Settings and preferences

### Phase 3: Polish & Features
- Advanced animation sequences
- Achievement system
- Data export/import
- Widget for home screen

## Technical Considerations

### Performance
- Efficient state updates to prevent UI lag
- Optimized GIF loading and caching
- Minimal battery drain during background state

### Data Persistence
- Daily progress auto-save on each increment
- Backup/restore functionality for user data
- Migration strategy for app updates

### Platform Support
- Primary: Android and iOS
- Responsive design for different screen sizes
- Native platform integrations (notifications, widgets)

## Deployment & Distribution

### AWS Amplify Configuration
- **Platform**: AWS Amplify for automated CI/CD
- **Repository**: GitHub integration for automatic deployments from `main` only
- **Build Settings**: Flutter web build configuration
- **Environment**: Production deployment with custom domain support

### Required Configuration Files

#### amplify.yml (Build Specification)
```yaml
version: 1
applications:
  - frontend:
      phases:
        preBuild:
          commands:
            - yum install -y xz
            - wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.7-stable.tar.xz -O flutter.tar.xz
            - tar xf flutter.tar.xz
            - export PATH="$PATH:`pwd`/flutter/bin"
            - flutter doctor
            - flutter pub get
        build:
          commands:
            - export PATH="$PATH:`pwd`/flutter/bin"
            - flutter build web --release
      artifacts:
        baseDirectory: build/web
        files:
          - '**/*'
      cache:
        paths:
          - flutter/**/*
          - ~/.pub-cache/**/*
          - .dart_tool/**/*
```

Only `main` deploys; see [ADR 0011](adr/0011-deploy-main-only.md). The repo's `amplify.yml` is the source of truth.

#### pubspec.yaml (Web Platform Configuration)
```yaml
flutter:
  uses-material-design: true
  web:
    pluginClass: MyPlugin
```

### Platform-Specific Builds
- **Web Version**: Flutter web build for AWS Amplify hosting
- **Mobile Apps**: Separate build processes for Play Store/App Store
- **Progressive Web App**: PWA configuration for mobile web experience

### Environment Variables
- **Production**: API endpoints, analytics keys
- **Staging**: Development/testing configurations
- **Feature Flags**: Toggle features for different deployment stages

### Domain & SSL
- **Custom Domain**: Configure through Amplify Console
- **SSL Certificate**: Automatic via AWS Certificate Manager
- **Redirects**: Configure HTTPS redirects and trailing slash handling

## Success Metrics
- Daily active usage during workout times
- Streak completion rates
- User retention beyond first week
- Feature adoption (running toggle usage, progress screen visits)