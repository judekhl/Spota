# Spota — Frontend Strategy

## Goal
Ship a premium-feeling mobile UI fast, using FlutterFlow as the primary build tool. No paid add-ons unless they solve a problem free tools cannot.

---

## Design Style
**Reference:** Google Maps, Waze, Uber — clean, functional, map-first.

| Principle | Application |
|-----------|-------------|
| Map is the hero | Full-screen map on launch, UI floats on top |
| Minimal chrome | No heavy nav bars; use bottom sheets and floating cards |
| Clear status at a glance | Color-coded availability (green / amber / red / grey for closed) |
| One primary action per screen | Navigate, Save, Update — never compete for attention |
| System fonts and dark/light | Use Flutter's default type scale; respect device theme |

Avoid decorative gradients, busy backgrounds, or custom icon sets. Flat, legible, fast.

---

## Build Approach

### Use FlutterFlow First
- Build all screens visually in FlutterFlow before touching exported code.
- Use **FlutterFlow AI** to scaffold screens from a text prompt, then refine.
- Use the **Component library** (cards, bottom sheets, list tiles) instead of building from scratch.
- Connect Supabase tables and realtime directly in FlutterFlow — no manual API wiring for standard CRUD.

### Export and Edit Only When Necessary
- Export Flutter code only when FlutterFlow's visual editor cannot do what is needed.
- Use Cursor or Claude Code for targeted edits to exported code (logic, custom widgets, bug fixes).
- Never re-import exported code back into FlutterFlow — treat export as one-way.

### Free Tools Only (Unless Blocked)
| Need | Free option |
|------|-------------|
| Map view | `google_maps_flutter` (free tier is sufficient for MVP) |
| Icons | Material Icons (built into Flutter) |
| Fonts | Google Fonts via FlutterFlow |
| Navigation deep-link | URL launcher to Waze / Google Maps |
| Realtime data | Supabase Realtime (included in free plan) |

---

## Screen Order (Build Priority)
1. Map / Home screen — core user value
2. Parking Lot Details sheet — drives the navigate action
3. Operator Login — gates the operator panel
4. Operator Dashboard — list of managed lots
5. Edit Lot screen — the only write surface

Build and test each screen before starting the next.
