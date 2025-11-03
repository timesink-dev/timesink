# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TimeSink is a virtual cinema platform built with Elixir/Phoenix that creates an immersive, community-driven film viewing experience. The platform enables curated film showcases, virtual theaters, and social engagement around cinema. See OVERVIEW.md for detailed domain concepts.

## Development Commands

### Setup
```bash
# Install Erlang/Elixir via asdf
asdf install

# Start Docker services (required for database)
docker compose up -d

# Setup database and dependencies
mix setup
```

### Running the Application
```bash
# Start development server with IEx shell
iex -S mix phx.server
# Access at http://localhost:4000
```

### Testing
```bash
# Run all tests
mix test

# Run specific test file
mix test test/path/to/test_file.exs

# Run tests matching a pattern
mix test --only tag_name

# Run static analysis (Dialyzer)
mix dialyzer
```

### Database
```bash
# Create and migrate database
mix ecto.setup

# Reset database (drop, create, migrate, seed)
mix ecto.reset

# Run migrations
mix ecto.migrate

# Rollback migration
mix ecto.rollback
```

### Assets
```bash
# Build assets (Tailwind + esbuild)
mix assets.build

# Deploy assets (minified)
mix assets.deploy
```

## Architecture

### Directory Structure

- **lib/timesink/** - Core business logic contexts
  - `account/` - User accounts, authentication, password management
  - `cinema/` - Films, showcases, theaters, exhibitions
  - `waitlist/` - Waitlist and invitation system
  - `payment/` - Payment processing (Stripe, BTCPay)
  - `storage/` - File storage (S3, Mux video)
  - `images/` - Image processing with Vix
  - `locations/` - Geographic location handling
  - `token/` - Token management (email verification, password resets)

- **lib/timesink_web/** - Web layer (Phoenix)
  - `live/` - Phoenix LiveView modules organized by feature
  - `controllers/` - Traditional Phoenix controllers (webhooks, redirects)
  - `components/` - Reusable UI components
  - `plugs/` - Request pipeline plugs for auth, etc.
  - `channels/` - Phoenix Channels and Presence

### Key Domain Concepts

- **Cinema** - The curated, communal film-watching experience
- **Showcase** - A time-bound collection of films (like a film festival)
- **Theater** - Virtual screening room where members watch films together
- **Exhibition** - Individual screening event of a film within a showcase
- **Film** - Individual movie/work available on the platform
- **Archives** - Historical collection of all previously showcased films
- **Member** - Registered user participating in the platform
- **Creative** - Filmmaker/contributor linked to films
- **Applicant** - Someone on the waitlist awaiting platform access

### Authentication & Authorization

- Uses custom JWT-based authentication (see `Timesink.Auth` and `TimesinkWeb.Auth`)
- Password hashing with Argon2
- Session tokens stored in session and optional "remember me" cookie
- Token types: email verification codes, password reset tokens, invite tokens
- Authentication plugs:
  - `RequireAuthenticatedUser` - Protects authenticated routes
  - `RequireAdmin` - Admin-only access
  - `RedirectIfUserIsAuthenticated` - Login/signup page redirects
  - `RequireInviteToken` - Onboarding flow protection

### LiveView Patterns

- LiveViews use `on_mount` callbacks for authentication (`:mount_current_user`, `:ensure_authenticated`, `:redirect_if_user_is_authenticated`)
- Layout switching via `live_session` with custom layouts (`LiveAppLayout`)
- Real-time features use Phoenix PubSub and Presence
- Admin panel uses Backpex for CRUD operations

### Background Jobs

- Oban for job processing with queues: `mailer`, `waitlist`
- Job workers in `lib/timesink/*/workers/`
- Cron jobs configured in `config/config.exs`
- Example: Waitlist invite scheduling and email sending

### External Services

Required environment variables (see `.envrc.template`):
- **Database**: PostgreSQL via Docker
- **Email**: Resend API for transactional emails
- **Storage**: S3-compatible (MinIO locally) + Mux for video
- **Payments**: Stripe and BTCPay Server
- **Location**: HERE Maps API
- **Auth**: Custom JWT with configurable salt

### Testing

- Test factories with ExMachina and Faker
- Mox for mocking external HTTP clients
- Test helpers in `test/support/`
- Tests run with isolated test database

## Important Notes

- The project uses Phoenix 1.7+ with LiveView as primary rendering engine
- Asset pipeline: Tailwind CSS + esbuild (no Node.js package manager)
- Schemas follow SwissSchema pattern for standardized CRUD
- Admin interface powered by Backpex library
- Theater scheduling uses GenServer (`Timesink.Cinema.TheaterScheduler`)
- User cache (`Timesink.UserCache`) for performance optimization
- Presence tracking for real-time theater occupancy
