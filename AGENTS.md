# 👑 Planea - Core Agent Playbook & Configuration

Welcome, AI Agent, to the **Planea** development workspace. This document serves as the absolute source of truth for the project's architecture, patterns, tech stack, and development methodologies. It is designed to ensure all contributions meet the highest standards of engineering, performance, security, and premium luxury UI design.

---

## 🛑 Critical Rule: Supabase MCP Server Alignment

> [!IMPORTANT]
> **MANDATORY MCP SERVER USAGE**
> You must **EXCLUSIVELY** use the **`supabase-planea`** MCP server for all database queries, migrations, and schema inspections. 
> 
> * **DO NOT** use the `supabase-novum` MCP server or any other database MCP servers configured on this system under any circumstances. Using the wrong MCP server will result in targeting the incorrect database instance, creating schema drift, or executing queries against an invalid context.
> * Always verify that any database tool calls you make are explicitly prefixed with or routed through `supabase-planea` (e.g., `mcp_supabase-planea_execute_sql`, `mcp_supabase-planea_apply_migration`, `mcp_supabase-planea_list_tables`, etc.).

---

## 🌐 Supabase Configuration & Schema Map

* **Project Name**: Planea
* **Supabase URL**: `https://omdfdwqwbkdwvbzcqbrz.supabase.co`
* **Primary MCP Server**: `supabase-planea`

### 🗄️ Database Tables & Relations

All tables in the `public` schema have Row-Level Security (RLS) enabled. Below is the operational mapping of the tables:

| Table Name | Description | Key Fields & Relations |
| :--- | :--- | :--- |
| `public.profiles` | User profiles synced with Supabase Auth | `id` (UUID, primary key matching Auth ID), `display_name`, `photo_url`, `created_at` |
| `public.events` | Core event details (weddings, galas, parties) | `id` (UUID), `name`, `organizer_id` (FK to profiles), `date_ms` (BigInt timestamp), `invite_code`, templates (`whatsapp_template`, `email_template`, `email_subject`) |
| `public.guests` | Guest list tracking and dietary/status management | `id` (UUID), `event_id` (FK to events), `name`, `status` (Invited, Confirmed, Declined, Pending), `dietary_requirements`, `notes` |
| `public.tables` | Physical tables laid out within a venue map | `id` (UUID), `event_id` (FK to events), `name`, `capacity` (Int), `pos_x` (Float), `pos_y` (Float), `shape` (Round/Square) |
| `public.seating_assignments` | Mappings connecting guests to seats at specific tables | `id` (UUID), `event_id` (FK to events), `table_id` (FK to tables), `guest_id` (FK to guests), `seat_number` (Int) |
| `public.venue_elements` | Non-table layout units (dance floor, stage, bar, etc.) | `id` (UUID), `event_id` (FK to events), `name`, `type`, `pos_x` (Float), `pos_y` (Float), `width` (Float), `height` (Float) |
| `public.collaborators` | Event permissions and multi-user collaboration roles | `id` (UUID), `event_id` (FK to events), `user_id` (FK to profiles), `email`, `role` (Organizer, Editor, Viewer), `status` (Invited, Pending, Approved) |

---

## 🛠️ Tech Stack & System Architecture

Planea is built on a modern, reactive, multi-platform framework designed for high-performance and absolute UI fidelity:

* **Framework**: **Flutter** (Multi-platform target: Web, iOS, Android).
* **State Management**: **`Provider`** paired with **`ChangeNotifier`**.
  * Dynamic reactivity is established using **`ChangeNotifierProxyProvider`** in `lib/main.dart` to automatically propagate state changes (e.g., updating the active user session or switching the current active event ID, which automatically cascades to rebuild the `SeatingProvider`, `ThemeProvider`, and `LocaleProvider`).
* **Navigation**: **`GoRouter`** (Declarative routing configured in `lib/app/app_router.dart`, reactively linked to authentication state).
* **Responsive Layouts**: **`ResponsiveFramework`** (Dynamic scaling across `MOBILE` `[0-480]`, `TABLET` `[481-900]`, and `DESKTOP` `[901+]`).
* **Backend Integration**: **Supabase** via `supabase_flutter`. Real-time subscriptions and database streams are combined reactively (e.g., using `CombineLatestStream` from `rxdart` inside `SupabaseService` to stream complete seating maps, guest lists, and physical elements).

### 📂 Directory Map

```text
lib/
├── app/          # Navigation config, routers (app_router.dart) and initialization
├── core/         # Cross-cutting concerns: extensions (l10n_extension.dart), utilities, themes, constants
├── data/
│   ├── models/   # Strictly typed serialization models representing database records
│   └── services/ # SupabaseService.dart containing CRUD, real-time streams, RPCs, and query wrappers
├── features/     # Feature-first modular directories containing screens, components, and local widgets
│   ├── auth/       # Authentication (Sign in, Register, Password reset)
│   ├── dashboard/  # Analytics, high-level overview, and statistics cards
│   ├── events/     # Event creation, detail visualization, and collaborator administration
│   ├── guests/     # Guest administration, filtering, statuses, and RSVP updates
│   ├── settings/   # Profile settings, theme options, and localization controls
│   ├── shared/     # Reusable premium components (glassmorphic containers, cards, buttons)
│   ├── shell/      # Main layout scaffold containing premium navigation sidebars and headers
│   └── tables/     # Drag-and-drop seating layout, seating charts, and canvas designer
└── providers/    # Centralized state management controllers coordinating service interactions with views
```

---

## 💎 Premium UI/UX & Design Guidelines

Planea targets the luxury and premium event market. The interface must look **breathtaking**, expensive, and sophisticated. Simple, default, or basic UI designs are strictly **unacceptable**.

### 🎨 Visual & Styling Standards

1. **Aesthetic Tone**: Premium, Luxury, Minimalist yet Elegant.
2. **Glassmorphism**: Always leverage high-end glassmorphic panels using Flutter's `BackdropFilter` with customized blur variables (`sigmaX: 10`, `sigmaY: 10`) combined with subtle, ultra-thin semi-transparent borders.
3. **Harmonious Color Palette**:
   * **Base Backgrounds**: Deep velvet black and rich dark greys (avoid plain pure black unless necessary, use polished dark hues).
   * **Accents**: Sophisticated gold and champagne gradients (`#D4AF37`, `#F3E5AB`), rose-gold highlights, or deep bronze contours.
   * **Feedback colors**: Muted emerald for success/confirmation, deep burgundy/rose for warning or decline, and muted sapphire for informational highlights.
4. **Typography**: Clean, geometric sans-serif fonts (e.g., **Montserrat**, **Outfit**, or **Inter**). Emphasize hierarchical balance: clear, wide tracking on headers, and high-readability layout configurations for detail fields.
5. **Micro-animations**: Use subtle transitions and hover effects to make the interface feel organic, highly responsive, and alive.

---

## 🌐 Localization (L10n) Flow

Planea is fully localized and supports multiple languages out-of-the-box. **NEVER hardcode display strings directly into widgets.**

### 📝 Step-by-Step L10n Methodology

1. **Modify Localizable Resources**: Add or edit key-value translation strings inside:
   * **English**: `lib/l10n/app_en.arb`
   * **Spanish**: `lib/l10n/app_es.arb`
2. **Generate Native Dart Bindings**: In the workspace terminal, execute:
   ```bash
   flutter gen-l10n
   ```
3. **Usage in Widgets**: Import the local extension `core/extensions/l10n_extension.dart` and retrieve strings using the responsive context:
   ```dart
   Text(context.l10n.eventDetailsTitle)
   ```

---

## 🚀 Step-by-Step Developer Playbook for AI Agents

When executing tasks or proposing code additions/modifications, follow these exact workflows to maintain project integrity:

### 1. Database Migrations (DDL Operations)
When changing the database structure, adding fields, or creating tables:
1. First, retrieve the current table structure with `mcp_supabase-planea_list_tables` using the `verbose: true` parameter.
2. Write clean SQL statements mapping your DDL modifications.
3. Call `mcp_supabase-planea_apply_migration` to execute migrations.
4. Provide a snake_case name detailing the database adjustment (e.g., `add_budget_spent_to_events`).
5. **Never** use hardcoded IDs inside migrations.

### 2. State & Data Sync Flow
When modifying data models or syncing data back and forth:
1. Ensure the model (`lib/data/models/*_model.dart`) has explicit `fromJson` and `toJson` methods matching the database schema.
2. Add the corresponding CRUD or stream listener method inside `SupabaseService` (`lib/data/services/supabase_service.dart`).
3. Wire the service method into the active Provider (`lib/providers/*_provider.dart`), utilizing `notifyListeners()` at the appropriate lifecycle stages.
4. For real-time sync, favor using `Stream` listeners over static `Future` fetches. Let the database act as the absolute single source of truth.

### 3. UI Implementation
When designing new screens or widgets:
1. Build with responsive layouts in mind, using `ResponsiveBreakpoints` constraints where needed.
2. Use premium shared components (`lib/features/shared/`) to maintain consistency in style, color schemes, and glassmorphism.
3. Never use raw colors (`Colors.red`, `Colors.green`); always utilize context theme tokens via `Theme.of(context)`.
4. Ensure all newly added interactive elements (buttons, inputs) are assigned unique and descriptive keys (`Key('widget_purpose')`) to aid automated integration testing.

### 4. Continuous Security Checks
Planea enforces strong database-level data security.
* After applying any migration or schema change, immediately run `mcp_supabase-planea_get_advisors` with `type: "security"`.
* Address any warning regarding missing RLS (Row-Level Security) policies or exposed columns instantly to safeguard client events.
