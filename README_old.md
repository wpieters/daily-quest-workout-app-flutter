# DailyQuest

A workout tracker app inspired by the One Punch Man/Solo Leveling workout routine with anime-style progression rewards.

I've been doing the classic One Punch Man workout (100 push-ups, 100 sit-ups, 100 squats, 10km run) but needed to ease into it gradually. Instead of doing it all at once, I break it down into hourly sessions - 10 reps of each exercise every hour for 10 hours to hit the daily target of 100. Since winter storms and deadlines make running impractical, I wanted a way to track this staged approach with some fun gamification.

This seemed like a perfect project to experiment with Flutter development and create something that would actually motivate me to stick with the routine.

## How It Works

The app provides a simple and engaging interface for tracking your daily workout progress:

- **Four Exercise Counters**: Large, prominent buttons for push-ups, sit-ups, squats, and running (100m per tap)
- **Stage-Based Progress**: Each exercise is divided into 10 stages of 10 reps each, with visual progress indicators
- **Flexible Running**: Toggle checkbox to include/exclude running from daily completion requirements
- **Anime-Style Rewards**: Goku power-up GIF animations when you complete your daily workout goal
- **Streak Tracking**: Progressive power-up animations based on consecutive days completed
- **Auto-Reset**: Counters automatically reset at midnight for a fresh daily challenge

## Features

- Cross-platform compatibility (iOS, Android, and Web)
- Intuitive tap-to-increment interface with haptic feedback
- Visual stage completion indicators (every 10 reps)
- Streak-based reward system with escalating power-up animations
- Local data persistence with automatic saving
- Running toggle for seasonal/weather flexibility
- Responsive design optimized for mobile workout sessions

## Live Demo

You can try the web version of the app here:
[DailyQuest Web App](https://dailyquest.duhblinn.xyz)

## Getting Started

This project is built with Flutter. To run it locally:

1. Ensure you have Flutter installed (see [Flutter installation guide](https://docs.flutter.dev/get-started/install))
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app on your connected device or emulator

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Development

This project was created as a practical solution to a personal fitness challenge while exploring Flutter development. It's designed around the staged workout approach I actually use, making it a real-world application rather than just a learning exercise.

The app architecture follows clean architecture principles with Riverpod for state management and focuses on smooth animations and responsive user interactions essential for workout tracking.

## Acknowledgements

- Workout routine inspired by One Punch Man manga/anime
- Power-up progression concept from Solo Leveling
- Animation sequences inspired by Dragon Ball Z transformation scenes