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
