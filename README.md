# RIPO-Flutter-APP

---   
### Stack:   
 - Flutter   
 - Dart   
 - Supabase   
 - Frog(optional)   

---   
 ### Team:   
  - [Tanvir Mahmud](https://github.com/i-mTanvir)   
  - [Redwan Rahman](https://github.com/Red1-Rahman)   
  - [Sudipta Paul](https://github.com/paul-shuvro)   
  - Enaiya Jannat  

---
### Localhost REST + SQLite (Phase 1)

This repo now includes a localhost-only backend in `backend/`:

- Stack: `shelf` + `sqlite3`
- DB file: `backend/data/ripo.sqlite3` (auto-created + auto-seeded)
- Base URL:
  - Desktop/Web: `http://127.0.0.1:8080`
  - Android emulator: `http://10.0.2.2:8080`

#### Run Backend

```bash
cd backend
dart pub get
dart run bin/server.dart
```

#### Run Backend Tests

```bash
cd backend
dart test
```

#### Seeded Login Accounts

- Customer: `customer@ripo.com` / `1234`
- Provider: `provider@ripo.com` / `1234`
- Admin: `admin@ripo.com` / `1234`

#### Thunder Client Setup

1. Create one environment: `Local`
2. Add variables:
    - `baseUrl = http://127.0.0.1:8080`
    - `androidEmulatorBaseUrl = http://10.0.2.2:8080`
3. Create collection: `RIPO Local API`
4. Add folders: `Auth`, `Customer`, `Booking`, `Provider`, `Admin`
5. Add requests in this order:
    - `POST {{baseUrl}}/auth/login`
    - `POST {{baseUrl}}/auth/register`
    - `POST {{baseUrl}}/auth/forgot-password`
    - `GET {{baseUrl}}/customer/services`
    - `GET {{baseUrl}}/bookings/availability?serviceId=1&date=2026-04-15`
    - `POST {{baseUrl}}/bookings/`
    - `GET {{baseUrl}}/provider/jobs`
    - `GET {{baseUrl}}/admin/dashboard`
    - `GET {{baseUrl}}/admin/users?role=customer`
    - `GET {{baseUrl}}/admin/finance`
6. In login request tests tab, save token as `authToken`
7. Add `Authorization: Bearer {{authToken}}` for protected routes

#### Implemented Endpoints

- Auth: login/register/forgot-password
- Customer: services list/recommended/categories/service-by-id
- Booking: availability/create/my bookings/details
- Provider: services list/status update, jobs list, accept/decline/complete
- Admin: dashboard/users/finance
