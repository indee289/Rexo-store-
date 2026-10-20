# Campster - Flutter

Premium influencer marketing platform connecting brands with creators for impactful campaigns.

## Tech Stack

- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Supabase** - Backend as a Service (Auth, Database, Storage, Realtime)
- **Riverpod** - State management
- **GoRouter** - Declarative routing

## Features

- User authentication (creators, brands, admins)
- Campaign management and creator applications
- Wallet for campaign earnings and withdrawal requests
- In-app messaging between users
- Product marketplace with orders
- KYC document verification
- Push notifications
- Admin panel for platform management

## Project Structure

```
lib/
  main.dart              # App entry point
  app.dart               # Root widget and app configuration
  core/
    constants/           # App-wide constants
    theme/               # Theme data and styling
    utils/               # Utility functions
    widgets/             # Shared widgets
    router/              # GoRouter configuration
  features/
    auth/                # Authentication screens and logic
    home/                # Home/dashboard feature
    campaigns/           # Campaign browsing and management
    shop/                # Product marketplace
    profile/             # User profile
    wallet/              # Wallet and transactions
    notifications/       # Notification center
    messages/            # In-app messaging
  services/              # Backend service integrations
```

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/indee289/Rexo-store-.git
   cd Rexo-store-
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up environment variables (Supabase credentials):
   - `SUPABASE_URL` - Your Supabase project URL
   - `SUPABASE_ANON_KEY` - Your Supabase anonymous key

4. Run the app:
   ```bash
   flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
   ```

## Android release

The Play release uses `minSdk 24`, `compileSdk 36`, and `targetSdk 36`.
Production release tasks fail if the upload keystore is missing; they never fall
back to debug signing. See [SIGNING.md](./SIGNING.md) for local setup and the
complete GitHub Actions secret list.

The `Flutter Build` workflow produces:
- `Campster.apk` for direct device testing;
- signed `Campster.aab` for Play Console;
- `release-info.txt` containing version, SDK, certificate and compatibility checks.

CI verifies the AAB signature against the configured keystore, API 24/36,
arm64 support, and 16 KB native-library ZIP alignment before uploading the
artifact.

## Database

The Supabase schema and migrations are under `supabase/`. Before production,
apply the current migrations/functions and test account deletion, reporting,
blocking, messaging, campaign applications, earnings, and withdrawals against
the live project.

## CI/CD

GitHub Actions workflow (`.github/workflows/flutter-build.yml`) handles the
signed Android release and rejects incomplete production configuration. See
[SIGNING.md](./SIGNING.md) for its required and optional secret names.
