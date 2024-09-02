
# IntelliFridge

IntelliFridge is a Flutter project designed to run on multiple platforms, including Chrome (Web), iOS, and Android. This README provides instructions on how to set up and run the project on each of these platforms.

## Prerequisites

Before you can run the IntelliFridge project, ensure you have the following installed on your system:

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Android Studio](https://developer.android.com/studio) (for Android development)
- [Xcode](https://developer.apple.com/xcode/) (for iOS development)
- A suitable IDE (e.g., [VS Code](https://code.visualstudio.com/) with Flutter and Dart plugins or Android Studio)
- [Chrome browser](https://www.google.com/chrome/) (for web development)

Make sure to set up your Flutter environment by following the official [Flutter installation guide](https://flutter.dev/docs/get-started/install).

## Getting Started

### 1. Install Dependencies

Run the following command to install the necessary dependencies:

\`\`\`bash
flutter pub get
\`\`\`

### 2. Running on Chrome (Web)

To run the project on Chrome, use the following command:

\`\`\`bash
flutter run -d chrome
\`\`\`

This will launch the IntelliFridge app in your default Chrome browser.

### 3. Running on iOS

**Note:** You need a macOS system with Xcode installed to run the project on iOS.

1. Connect your iOS device or use the iOS simulator.
2. Run the following command:

\`\`\`bash
flutter run -d ios
\`\`\`

This will build and launch the IntelliFridge app on your connected iOS device or simulator.

### 4. Running on Android

1. Connect your Android device or use an Android emulator.
2. Run the following command:

\`\`\`bash
flutter run -d android
\`\`\`

This will build and launch the IntelliFridge app on your connected Android device or emulator.

## Additional Configuration

### For iOS

Ensure that you have set up your signing and capabilities in Xcode. Open the \`ios/Runner.xcworkspace\` file in Xcode, and configure the necessary team and provisioning profile settings.

### For Android

Make sure that you have an Android Virtual Device (AVD) set up in Android Studio or have connected a physical device.

## Troubleshooting

If you encounter any issues while running the project, try the following:

- Ensure that your Flutter environment is properly configured by running \`flutter doctor\` and following the instructions to resolve any issues.
- Make sure all dependencies are installed correctly using \`flutter pub get\`.
- For iOS, ensure that Xcode is properly configured with the necessary signing credentials.

## Contributing

If you'd like to contribute to IntelliFridge, feel free to open a pull request or report issues in the GitHub repository.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
