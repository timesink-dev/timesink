# TS-111: Director Commentary Feature

## Overview

Director Commentary extends the Audience Notes system to give verified film directors a private, on-demand screening room where they can leave timestamped commentary on their films. This commentary propagates to all exhibitions of the film in the normal theater view, displayed in a dedicated tab alongside (but distinct from) audience notes.

---

## Access & Authorization

### Primary Access
A user gains director access to a film's private screening room if they have:
1. A verified Creative profile (admin-approved claim)
2. A `film_creative` record linking them to that film with title `"Director"`

This check must be enforced at both the router/plug level and within the LiveView `on_mount`.

### Secondary Access (Escape Hatch)
A TimeSink admin can issue a signed URL granting access to a specific film's director screening room. This covers edge cases such as:
- A director who has not yet claimed their creative profile
- A distributor or representative acting on behalf of a director

The signed token should:
- Be scoped to a specific `film_id`
- Have a configurable expiry (default: 7 days)
- Grant a session-level flag upon validation (not a permanent credential)
- Be single-use or revocable by an admin

---

## Routes

| Route | Description |
|---|---|
| `/films/:title_slug/director` | Private screening room for director commentary |
| `/account/films` (or similar) | Private dashboard listing all films the user directs |

The screening room route is completely isolated from the theater/exhibition infrastructure — no Presence, no PubSub, no audience access.

---

## Private Dashboard

A new section on the authenticated user's private account area (not their public creative profile) titled **"Your Films"** or **"Director's Commentary"**.

- Lists all films where the user holds a verified Director creative credit
- Each entry links to `/films/:title_slug/director`
- Only visible to the authenticated owner — not rendered on public profile pages

---

## Director Commentary Data Model

Director commentary reuses the existing `Timesink.Cinema.Note` schema, differentiated by `source: :director`. The schema already includes a `source` enum (`:audience` | `:director`).

### Migration Changes Required
The existing `note` table has `exhibition_id` as `NOT NULL`. A migration must:
1. Make `exhibition_id` nullable
2. Add a `film_id` foreign key column (nullable for backwards compatibility with audience notes)
3. Add a database-level check constraint: a note must have either `exhibition_id` OR `film_id` set, not neither

### Resulting Note Shape by Source

| Field | Audience Note | Director Commentary |
|---|---|---|
| `source` | `:audience` | `:director` |
| `exhibition_id` | required | `nil` |
| `film_id` | `nil` | required |
| `user_id` | required | required |
| `body` | plain text | plain text |
| `offset_seconds` | integer | integer |
| `status` | `:visible` / `:hidden` / `:flagged` | `:visible` / `:hidden` / `:flagged` |

### Key Behaviors
- Director commentary is **retroactive** — edits and deletions immediately affect all past and future exhibitions of the film
- A director can have multiple commentary entries at different timestamps on the same film
- No rich text; plain text only
- Soft character limit: 500 chars, with a counter warning activating at 450

---

## Private Screening Room UX

### Layout
- **Left/main area**: On-demand video player with full playback controls (play, pause, seek, scrub)
- **Right panel**: Commentary management panel

### Adding Commentary
1. Director pauses the film at the desired timestamp
2. Clicks **"Add Commentary"** button
3. A text input appears (plain text, 500 char soft limit)
4. A character counter is visible; warning style activates at 450 characters
5. Submitting saves the comment at the current player timestamp

### Commentary Panel
- Lists all existing commentary in ascending timestamp order
- Each entry displays:
  - Formatted timestamp (e.g., `1:24:07`)
  - Comment body (truncated if needed, expandable)
  - Edit and Delete actions
- **Clicking any comment seeks the player to that comment's timestamp**

### Editing & Deleting
- Edit opens an inline text field pre-populated with the existing body
- Delete prompts a confirmation before removing
- Changes are applied immediately and propagate retroactively to all exhibitions

---

## Theater View Display

Director commentary appears in the theater's existing note/commentary UI under a **dedicated tab**, separate from the Audience Notes tab.

### Visual Treatment
- A **Director badge** (film reel icon or similar) on each comment
- **Warm/gold color tone** to distinguish from audience note styling
- Director's name links to their public creative profile
- Comments are **read-only** in theater view — no interaction beyond reading

### Sync Behavior
- Commentary syncs with the film playback timestamp, appearing at the correct moment during a live exhibition — the same mechanism used for audience notes

---

## Edge Cases & Constraints

| Scenario | Handling |
|---|---|
| Director has no verified claim on any film | Dashboard shows empty state with prompt to claim creative profile |
| Admin token expires mid-session | Session flag persists for that session; next visit requires a new token |
| Director is removed as a film creative after leaving commentary | Comments persist on the film; access to the screening room is revoked |
| Multiple directors on one film | Each verified Director creative gets independent access; both can leave commentary |
| Director edits a comment during a live exhibition | Change is immediately reflected for viewers in that exhibition |

---

## Out of Scope (v1)

- Rich text or media attachments in commentary
- Audience-facing reactions to director commentary
- Director commentary visible on public film pages outside of exhibitions
- Notifications to directors when their film is screened
- Analytics on commentary engagement
