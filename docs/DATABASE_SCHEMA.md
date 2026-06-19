# Spota — Database Schema (MVP)

All tables live in Supabase (PostgreSQL). No gate integrations — all data is updated manually by operators.

---

## Table: operators

Stores operator accounts. Authentication is handled by Supabase Auth; this table holds profile data.

| Field | Type | Purpose |
|-------|------|---------|
| id | uuid (PK) | Unique operator ID — matches Supabase Auth user ID |
| email | text | Operator login email |
| name | text | Display name of the operator or company |
| created_at | timestamp | When the account was created |

---

## Table: parking_lots

One row per parking lot. Operators own one or more lots.

| Field | Type | Purpose |
|-------|------|---------|
| id | uuid (PK) | Unique lot ID |
| operator_id | uuid (FK → operators.id) | Which operator manages this lot |
| name | text | Display name of the lot |
| address | text | Street address in Haifa |
| latitude | float | Map marker position |
| longitude | float | Map marker position |
| total_spaces | integer | Total capacity of the lot |
| available_spaces | integer | Current available spaces (updated manually) |
| price | text | Price info (e.g. "5 ₪/hr" or "Free") |
| is_open | boolean | Whether the lot is currently open |
| updated_at | timestamp | When availability was last updated |

---

## Table: parking_updates

Audit log of every manual update made by an operator.

| Field | Type | Purpose |
|-------|------|---------|
| id | uuid (PK) | Unique update ID |
| lot_id | uuid (FK → parking_lots.id) | Which lot was updated |
| operator_id | uuid (FK → operators.id) | Who made the update |
| available_spaces | integer | Value set at time of update |
| price | text | Price value set at time of update |
| is_open | boolean | Open/closed value set at time of update |
| created_at | timestamp | When this update was submitted |
