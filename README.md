# JSON Viewer

A cross-platform Flutter application for viewing, navigating, and annotating JSON files with ease.

## Features

- Open and display JSON files in a tree view
- Double-click to select fields, right-click for actions
- Copy Python-style access paths for any field
- Add, edit, and save comments for any field (comments saved as YAML)
- Highlight selected fields for better navigation
- Cross-platform: Windows, macOS, Linux, Web, Android, iOS

## Environment

Before you start, make sure your environment meets the following requirements:

- **Flutter**: 3.32.5 (Channel stable)
- **Dart**: 3.8.1
- **Visual Studio**: Community 2022 17.14.8 (for Windows desktop development)
- **Windows Version**: 11 专业版 64-bit, 23H2, 2009
- **VS Code**: 1.101.2 (optional, for code editing)

You can check your environment by running:

```bash
flutter doctor -v
```

**Sample Output:**
```
Flutter (Channel stable, 3.32.5, on Microsoft Windows [版本 10.0.22631.5549], locale zh-CN)
• Flutter version 3.32.5 on channel stable at C:\flutter
• Dart version 3.8.1
• Visual Studio Community 2022 version 17.14.36301.6
• Windows 10 SDK version 10.0.26100.0
• VS Code, 64-bit edition (version 1.101.2)
• Chrome (web), Edge (web), Windows (desktop)
```

### Note for users in Mainland China
If you are in Mainland China, it is recommended to set the following environment variables to use Flutter's official mirrors for faster dependency downloads:

```powershell
# For PowerShell (Windows)
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
```
Or for CMD:
```cmd
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart (comes with Flutter)

### Installation
1. Clone this repository:
   ```bash
   git clone <repo-url>
   cd json_viewer
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. (Optional) Check your environment:
   ```bash
   flutter doctor -v
   ```

### Running the App
- **Analyze App :**
   ```bash
   flutter analyze
   ```
- **Debug mode choose platform :**
  ```bash
  flutter run -v
  ```
- **Debug mode for Windows :**
  ```bash
  flutter run -d windows
  ```
- **Build for Windows:**
  ```bash
  flutter build windows
  ```
- For other platforms, use the corresponding Flutter build command (e.g., `flutter build macos`, `flutter build apk`, etc.)

## Usage
1. Launch the app.
2. Click the folder icon in the top-right to open a JSON file.
3. Navigate the JSON structure in the tree view.
4. Double-click a field to select it. Right-click (or long-press on mobile) for more actions:
   - Copy Python path: Copies the access path (e.g., `['key1']['key2']`) to clipboard.
   - Add/Edit comment: Attach a note to the field (saved in a YAML file alongside your JSON).
5. Comments are shown next to values and are persistent per file.

## Screenshots
<!-- Add screenshots here if available -->

## Contributing
Contributions are welcome! Please open issues or pull requests for bug fixes, features, or suggestions.

## License
This project is licensed under the MIT License.
