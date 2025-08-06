# DailyQuest - Solo Leveling Workout Tracker 🏋️‍♂️

A Flutter mobile app that tracks daily workout progress for the One Punch Man/Solo Leveling workout routine with staged progression and animated rewards.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-7C4DFF?style=for-the-badge&logo=flutter&logoColor=white)

## Features ✨

### Core Functionality
- **Four Exercise Types**: Push-ups, Sit-ups, Squats (100 reps each), Running (10km)
- **Stage System**: Each exercise divided into 10 stages of 10 reps each
- **Daily Reset**: Counters automatically reset at midnight
- **Running Toggle**: Enable/disable running from daily completion requirements
- **Progress Tracking**: Visual progress bars and stage completion indicators

### Gamification Elements
- **Power Level System**: Anime-inspired progression based on streak length
  - Basic Power (1-7 days) - Blue aura
  - Super Saiyan 1 (8-30 days) - Yellow aura  
  - Super Saiyan 2 (31-100 days) - Gold aura
  - Ultra Instinct (100+ days) - Silver aura
- **Completion Rewards**: Celebration animations when daily goals are achieved
- **Streak Tracking**: Current and longest streaks with visual indicators

### User Experience
- **Large Touch Targets**: Optimized for workout use
- **Haptic Feedback**: Button press confirmation
- **Stage Animations**: Smooth micro-animations for interactions
- **Dark Theme**: Anime-inspired color scheme with power level progression
- **Offline First**: All data stored locally with SharedPreferences

## Screenshots 📱

(Screenshots would go here)

## Architecture 🏗️

### Clean Architecture
- **Features**: Modular feature-based organization
- **Data Layer**: Local storage with SharedPreferences
- **Domain Layer**: Business logic and models
- **Presentation Layer**: UI components and state management

### State Management
- **Riverpod**: Reactive state management
- **Providers**: Separate providers for workout data, user progress, and settings
- **Async States**: Proper loading and error handling

### Data Models
- `WorkoutDay`: Daily exercise progress with completion tracking
- `UserProgress`: Streaks, achievements, and power level calculation
- `ExerciseType`: Enum with formatting and target information

## Getting Started 🚀

### Prerequisites
- Flutter SDK (>=3.5.4)
- Dart SDK
- IDE (VS Code, Android Studio, etc.)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/daily-quest-workout-app-flutter.git
   cd daily-quest-workout-app-flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code (JSON serialization)**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

#### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web (PWA)
```bash
flutter build web --release --web-renderer canvaskit
```

## Deployment 🌐

### AWS Amplify (Web)
The project includes `amplify.yml` configuration for automated deployment:

1. Connect your repository to AWS Amplify
2. Amplify will automatically detect the configuration
3. Deploy with optimized web renderer for animations

### PWA Features
- **Installable**: Can be installed on mobile devices
- **Offline Capable**: Works without internet connection
- **Responsive**: Optimized for mobile and desktop

## Development 🛠️

### Project Structure
```
lib/
├── app/
│   └── navigation/          # App navigation
├── core/
│   ├── constants/          # App constants and theme
│   ├── utils/              # Utility functions
│   └── extensions/         # Dart extensions
├── features/
│   ├── workout/           # Workout tracking feature
│   │   ├── data/          # Providers and data management
│   │   ├── domain/        # Business logic
│   │   └── presentation/  # UI screens and widgets
│   ├── progress/          # Progress tracking feature
│   └── settings/          # App settings
└── shared/
    ├── models/            # Data models
    ├── services/          # Shared services
    └── widgets/           # Reusable widgets
```

### Key Dependencies
- `flutter_riverpod`: State management
- `shared_preferences`: Local data storage  
- `json_annotation`: JSON serialization
- `lottie`: Animations (planned)
- `lucide_icons`: Modern icons

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Testing 🧪

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

## Roadmap 🗺️

### Phase 1: Core Functionality ✅
- [x] Basic UI with exercise buttons
- [x] Local storage for daily progress  
- [x] Stage tracking and visual indicators
- [x] Running toggle functionality
- [x] Progress history screen

### Phase 2: Enhanced UX
- [ ] Advanced animation sequences (Lottie/GIF)
- [ ] Achievement system
- [ ] Data export/import
- [ ] Settings screen with customization

### Phase 3: Polish & Features  
- [ ] Home screen widget
- [ ] Notification reminders
- [ ] Social sharing
- [ ] Multiple workout routines

## Usage Instructions 📖

### Daily Workout Flow
1. **Open the app** to see your current day's progress
2. **Tap exercise buttons** to increment counters:
   - Push-ups, Sit-ups, Squats: +1 rep per tap
   - Running: +100m per tap (target: 10km)
3. **Watch progress bars fill** as you complete stages (every 10 reps)
4. **Toggle running** on/off if you want to skip it for daily completion
5. **Complete all enabled exercises** to unlock celebration animation
6. **View progress screen** to see your workout history and streaks

### Power Level System
Your power level increases based on consecutive completed days:
- **Days 1-7**: Basic Power (Blue) 🔵
- **Days 8-30**: Super Saiyan 1 (Yellow) 🟡  
- **Days 31-100**: Super Saiyan 2 (Gold) 🟠
- **Days 100+**: Ultra Instinct (Silver) ⚪

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments 🙏

- Inspired by **One Punch Man** anime and the legendary Saitama workout routine
- **Solo Leveling** power progression system
- Flutter and Dart communities for excellent documentation

---

**Made with ❤️ and Flutter**

Start your journey to become the strongest! 💪
