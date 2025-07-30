# JSON Viewer

A cross-platform Flutter application for viewing, navigating, and annotating JSON files with ease.

## Features

- **1. JSON Visualization**: Open and display JSON files in an expandable tree view
- **2. Field Operations**: Double-click to select fields, right-click for context menu actions
- **3. Path Copying**: Copy Python-style access paths for any field (e.g., `['key1']['key2']`)
- **4. Annotation System**: Add, edit, and save comments for any field (comments saved as YAML)
- **5. JSON Compression**: Automatically compress long JSON data for better readability and to reduce Token usage when copying to ChatGPT-like applications.
- **6. Cross-platform**: Windows, macOS, Linux, Web, Android, iOS

## Usage
1. Navigate the JSON structure in the tree view.
2. Double-click a field to select it. Right-click (or long-press on mobile) for more actions:
   - Copy Python path: Copies the access path (e.g., `['key1']['key2']`) to clipboard.
   - Add/Edit comment: Attach a note to the field (saved in a YAML file alongside your JSON).
   - Note: Comments are shown next to values and are persistent per file.
3. JSON Compression: Compress long JSON data for better readability.
### JSON Compression Feature
The application will automatically compress JSON data when opened:
- Long strings (>20 characters) are truncated with ellipsis
- Arrays with more than 2 items show only the first two elements
- Object structures remain fully intact

**Compression Example:**

Original JSON:
```json
{
  "name": "Sample JSON with long content",
  "description": "This is an example of a very long text that would be truncated in the compressed view",
  "tags": ["json", "viewer", "compression", "example"],
  "metadata": {
    "version": 1.0,
    "author": "JSON Viewer Team",
    "created": "2023-09-15T10:30:00Z"
  }
}
```

Compressed View:
```json
{
  "name": "Sample JSON with long content",
  "description": "This is an example of a very long text that would be...",
  "tags": ["json", "viewer"],
  "metadata": {
    "version": 1.0,
    "author": "JSON Viewer Team",
    "created": "2023-09-15T10:30:00Z"
  }
}
```

## Environment

Before you build the app, make sure your environment meets the following requirements:

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
- **Analyze code :**
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

## Screenshots
<!-- Add screenshots here if available -->

## Contributing
Contributions are welcome! Please open issues or pull requests for bug fixes, features, or suggestions.

## License
This project is licensed under the MIT License.
