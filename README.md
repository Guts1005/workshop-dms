# Workshop DMS

Flutter workshop application with Supabase authentication, workshop-scoped customer and vehicle records, applications, check-in photos, condition reports, and estimates.

## Project status

This is an active prototype, not a complete production DMS. See [Build progress](BUILD_PROGRESS.md) for a short status and [the developer handoff](docs/DEVELOPER_HANDOFF.md) for the remaining work, architecture notes, and verified setup path.

## Run locally

Install Flutter and the platform build tools, then fetch dependencies:

```powershell
flutter pub get
Copy-Item env.example.json env.json
```

Edit `env.json` with your Supabase URL and publishable key, then run:

```powershell
flutter run --dart-define-from-file=env.json
```

Run checks with:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

Do not commit the local `env.json`. Do not add Supabase service-role keys, passwords, customer information, or real vehicle records to the repository.

## Connect Supabase

1. Create a Supabase project and copy its project URL and publishable key.
2. Apply the SQL migration in `supabase/migrations/` to that project. With the Supabase CLI, link the project and run `supabase db push`; the SQL editor can also run the migration file.
3. Copy `env.example.json` to `env.json` and set `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`.
4. Run the app with `flutter run --dart-define-from-file=env.json`.
5. Create an account and workshop in the app. Supabase email confirmation settings determine whether the first sign-in requires email confirmation.

`env.json` is ignored by Git. The app uses only the publishable key; never put a Supabase service-role key in a Flutter app. The migration enables row-level security for workshop data and creates a private bucket for check-in photos.

Without project configuration the app shows a setup screen and does not create sample records. Empty tables produce empty states throughout the app.
