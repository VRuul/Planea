# Planea - Agents Configuration

This file provides context for AI agents working on the Planea project.

## Supabase Configuration

The project is connected to a specific Supabase instance. Agents should use the following details for database operations, migrations, and debugging.

- **Project Name**: Planea
- **Supabase URL**: `https://omdfdwqwbkdwvbzcqbrz.supabase.co`
- **MCP Server**: `supabase-planea`

### Database Schema

The database follows a schema designed for event planning and guest management. Key tables include:

- `public.events`: Core event details (weddings, parties, etc.).
- `public.guests`: Guest list management (status, seating requirements).
- `public.tables`: Table layout and capacity for venues.
- `public.seating_assignments`: Mapping of guests to specific tables and seats.
- `public.collaborators`: User permissions and roles for event management.
- `public.venue_elements`: Physical elements of the venue (dance floor, stage, etc.).

## Tech Stack & Architecture

- **Framework**: Flutter (Multi-platform: Web, iOS, Android).
- **State Management**: `Provider` + `ChangeNotifier`.
- **Navigation**: `GoRouter` (Configured in `lib/app/app_router.dart`).
- **Responsive UI**: `ResponsiveFramework` for adaptive layouts.
- **Backend**: Supabase (Auth, Database, Realtime).

## UI/UX Guidelines

- **Aesthetic**: Premium, Luxury, Elegant.
- **Design Patterns**: Glassmorphism (using `BackdropFilter`), smooth gradients.
- **Color Palette**: Dark mode primary, gold/champagne accents for highlights.
- **Typography**: Modern and clean (e.g., Montserrat/Outfit).

## Project Structure

- `lib/core`: Utilities, extensions, and constants.
- `lib/data/models`: Data entities and JSON serialization.
- `lib/features`: Modular features (Auth, Events, Guests, etc.).
- `lib/providers`: Centralized state management.
- `lib/l10n`: Localization files (`.arb`).

## Instructions for Agents

1. **Schema Changes**: Always use `apply_migration` via the `supabase-planea` MCP for DDL operations.
2. **Data Operations**: Use `execute_sql` for data manipulation or troubleshooting.
3. **Localization**: When adding or modifying UI text, update the `.arb` files in `lib/l10n` and use `context.l10n`.
4. **Style Consistency**: Follow the premium glassmorphism design language for any new UI components.
5. **Logs**: Check `get_logs` if encountering issues with Edge Functions or API calls.
