# MP_Calandar_App

Chrono - a calendar app with a scheduling assistant. Group project for Mobile Programming (CAU, Fall 2026).

## How to run

The assistant uses the OpenRouter API with its free models, so you need a key from https://openrouter.ai/settings/keys

1. Copy `.env.example` to `.env` (git ignores this file, never commit your key)
2. Put your key in `.env`
3. Run the app with the key:

```
flutter pub get
flutter run --dart-define-from-file=.env
```

Everything except the assistant also works with just `flutter run`.

A free account gets 50 requests a day. `OPENROUTER_API_KEY_2` to `_4` are optional keys from other accounts. When a key
has used up its requests for today, the app tries the next one. Leave the ones you don't have empty.

## Building the APK

The keys in `.env` are built into the app, so whoever installs the APK can use the assistant:

```
flutter build apk --release --dart-define-from-file=.env
```

The APK ends up in `build/app/outputs/flutter-apk/app-release.apk`.
