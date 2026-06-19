# Spota — Project Instructions

## What is Spota
A mobile app for real-time parking availability in Haifa, Israel.

## MVP Scope
**User app:**
- Find nearby parking lots
- See available spaces, prices, and open/closed status
- Navigate to a lot via Waze or Google Maps

**Operator panel:**
- Manually update available spaces, price, and open/closed status

No parking-gate integrations. No payment flows. Manual updates only.

## Tech Stack
| Tool | Role |
|------|------|
| FlutterFlow | Build screens visually, connect Supabase, test |
| Supabase | Database, realtime availability, operator data |
| Cursor | Review codebase, smaller edits, debug exported Flutter code |
| Claude Code | Edit code, run commands, fix bugs, refactor |
| ChatGPT | Strategy, product decisions, database planning, write prompts |

## Workflow Rules
- One feature per prompt — never build the whole app at once.
- Test after every feature before moving on.
- Save working versions regularly.
- Never paste secret API keys into any chat.
- Do not let two AI agents edit the same files simultaneously.

## Claude Code Behavior
- Stay within MVP scope unless the user explicitly expands it.
- Edit only the files relevant to the current task.
- Do not add features, abstractions, or error handling beyond what is asked.
- No comments unless the reason is non-obvious.
