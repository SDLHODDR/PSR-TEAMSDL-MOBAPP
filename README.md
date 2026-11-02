# SDL PSR Flutter Starter

## Structure (MVC-inspired)
- `models/`: data model classes (add typed models as the app grows)
- `views/pages/`: screens
- `views/widgets/`: reusable UI widgets (add reusable cards here)
- `controllers/`: UI orchestration/state (can be added per feature)
- `services/`: local JSON loader now; later PHP API client
- `core/`: theme and shared utilities
- `assets/data/`: static sample JSON

This initial compact starter reads static JSON directly through `MockDataService` to keep the first setup beginner-friendly. As we add features, we will move parsing into typed models and controller classes.

## Windows + VS Code setup
1. Install Flutter SDK: https://docs.flutter.dev/get-started/install/windows/mobile
2. Install VS Code: https://code.visualstudio.com/
3. VS Code → Extensions → install **Flutter** (Dart is installed with it).
4. For Android emulator, install Android Studio and use its SDK Manager to install Android SDK + platform tools. Or use a physical Android phone with Developer options and USB debugging.
5. Open PowerShell and run `flutter doctor`. Fix Android toolchain items it reports.
6. Extract this ZIP and open the `SDL_PSR_Flutter_Starter` folder in VS Code.
7. VS Code → Terminal → New Terminal, then run:
   ```powershell
   flutter pub get
   flutter doctor
   flutter devices
   flutter run
   ```

## Demo login
Employee code is prefilled with `05262`. The demo accepts any password and does not send credentials anywhere. Do not use this login for production.

## Edit sample data
Edit:
- `assets/data/dashboard.json`
- `assets/data/route.json`
- `assets/data/products.json`
- `assets/data/orders.json`

Because these are declared as Flutter assets in `pubspec.yaml`, run `flutter pub get` after changing asset declarations. After changing JSON contents, hot restart if the app does not refresh.

## Production direction
Flutter → HTTPS PHP API → Oracle. Never connect the mobile app directly to Oracle. Firebase Cloud Messaging can be added for push notifications after authentication and backend device-token registration are ready. Prices and names here are sample-only.
"# PSR-TEAMSDL-MOBAPP" 
