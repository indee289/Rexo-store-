# Rexo Marketplace - Flutter

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
- Wallet system with deposits and withdrawals
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

## Build

Build a release APK:
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key
```

## Database

The Supabase schema is located at `supabase/schema.sql`. It includes:
- 17 tables with proper relationships and constraints
- Row Level Security (RLS) policies for all tables
- Performance indexes on frequently queried columns
- Storage buckets for file uploads
- Auto-wallet creation trigger

### Phase 1 Critical Fixes (✅ Implemented)

Recent critical database fixes have been implemented to resolve schema mismatches:

1. **Subscription Plans Schema Alignment**: Added `interval` column for seed script compatibility
2. **Wallet Function Aliases**: Added `credit_wallet` and `debit_wallet` functions for admin operations
3. **Subscription Payments Integration**: Integrated subscription_payments table into main schema

For complete documentation, see:
- [Phase 1 Implementation Guide](./PHASE_1_CRITICAL_FIXES_GUIDE.md)
- [Database Schema Changes](./DATABASE_SCHEMA_CHANGES.md)
- [API Function Updates](./API_FUNCTION_UPDATES.md)
- [Deployment Procedures](./DEPLOYMENT_PROCEDURES.md)
- [Operational Procedures](./OPERATIONAL_PROCEDURES.md)

## CI/CD

GitHub Actions workflow (`.github/workflows/flutter-build.yml`) handles:
- Flutter setup and dependency installation
- Code analysis
- Release APK build
- Artifact upload

Required GitHub Secrets:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
