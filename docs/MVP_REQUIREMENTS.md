# Spota — MVP Requirements

## User Screens

### 1. Map / Home Screen
- Map view centered on Haifa
- Markers for nearby parking lots
- Each marker shows available spaces (or full/closed indicator)

### 2. Parking Lot Details Screen
- Lot name and address
- Current available spaces
- Price (per hour or flat rate)
- Open / closed status
- "Navigate" button — opens Waze or Google Maps

## Operator Screens

### 1. Operator Login
- Email and password login via Supabase Auth
- Access restricted to verified operators

### 2. Operator Dashboard
- List of lots managed by this operator
- Each lot shows current spaces, price, and status

### 3. Edit Lot Screen
- Update available spaces (numeric input)
- Update price (text or numeric input)
- Toggle open / closed status
- Save button — writes to Supabase in real time

## Out of Scope (MVP)
- Parking-gate or sensor integrations
- In-app payments or reservations
- User accounts or saved favorites
- Push notifications
- Reviews or ratings
- Admin panel beyond operator self-management
- Multi-city support
- Parking history or analytics
