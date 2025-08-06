Create a Flutter workout tracker app called "DailyQuest" inspired by One Punch Man/Solo Leveling workouts.

## Core Functionality:

- Four large, prominent buttons in a grid layout for: Push-ups, Sit-ups, Squats, and Running
- Each tap increments: Push-ups/Sit-ups/Squats by 1 rep, Running by 100m
- Target: 100 reps for exercises, 10km (100 taps) for running
- Display current count / target count on each button
- Visual progress bars or rings showing completion percentage

## Stage System:

- Each exercise divided into 10 stages of 10 reps each
- Show stage completion visually (e.g., 3/10 stages completed)
- Celebrate each stage completion with small animation/effect

## Running Toggle:

- Checkbox below running button to enable/disable running from daily completion
- When disabled, daily completion only requires the three exercises at 100 reps each

## Completion Rewards:

- When all enabled exercises reach their targets, trigger celebration animation
- Use Lottie animations or GIFs for power-up sequences (Goku/Dragon Ball style)
- Different animations based on consecutive days completed (streak system)

## Data Persistence:

- Save progress locally using SharedPreferences
- Track daily completion streaks
- Auto-reset counters at midnight
- Store workout history

## UI Design:

- Anime-inspired color scheme (blue → yellow → red for power levels)
- Large, accessible buttons optimized for workout use
- Bold, easy-to-read counter numbers
- Smooth animations for increments and progress
- Dark theme friendly for various lighting conditions

## Additional Features:

- Haptic feedback on button taps
- Simple settings screen for customization
- Progress history view showing past workouts and streaks
- Responsive design for different screen sizes

## Technical Requirements:

- Use Riverpod or Provider for state management
- Clean architecture with proper separation of concerns
- Optimized for both mobile and web deployment
- PWA-ready for web installation on mobile devices

The app should feel motivating and gamified while being practical for actual workout tracking. Focus on smooth performance and intuitive interactions since users will be tapping frequently during workouts.
