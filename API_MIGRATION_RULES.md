# API Migration Rules

## Source of Truth
- The OpenAPI specification at `assets/api/openapi.json` is the **sole source of truth** for all backend API contracts.
- No endpoint, request body, response field, or parameter should be used unless it is defined in the spec.
- If the spec and existing code disagree, the spec wins.

## Allowed Headers
Only these four custom headers may be sent on requests to identify the service module:

| Header     | Endpoint Tags                     |
|------------|-----------------------------------|
| `Auth`     | All `/api/v1/auth/*` endpoints    |
| `Routing`  | All `/api/v1/route*` endpoints    |
| `Transit`  | All `/api/v1/lines*`, `/api/v1/stops*` endpoints |
| `User`     | All `/api/v1/user/*` endpoints    |

- For login, register, and google-login: **no auth token** is required (`includeAuth: false`).
- For all other endpoints: the **JWT Bearer token** from `SharedPreferences` is injected automatically.

## Endpoint Naming Convention
- All backend paths **must** use the `/api/v1/` prefix.
- Path parameter placeholders use `{param}` in the spec; in code use Dart string interpolation.

## Request/Response Model Rules
1. Every request model **must** have a `toJson()` method that matches the spec's `property name` casing exactly.
2. Every response model **must** have a `factory fromJson(Map<String, dynamic>)` constructor.
3. All date/time fields use **ISO 8601 strings** (`DateTime.parse` / `toIso8601String()`).
4. All numeric fields use `num` in JSON; cast with `.toInt()` or `.toDouble()` as appropriate.
5. Optional fields in the spec **must** be nullable (`Type?`) in Dart, and omitted from JSON when null.
6. Do **not** add fields that are not present in the spec.

## Service Layer Rules
1. `ApiService` is the only HTTP client. No other Dio or `http` instances should call backend endpoints.
2. Each feature domain gets its own service class (e.g., `AuthService`, `RouteService`, `UserService`, `TransitService`).
3. Services delegate all HTTP calls to `ApiService` — they do not create their own Dio instances.
4. External/public APIs (Nominatim, OSRM, Overpass, Google Places) may keep using the `http` package directly — they are not part of this migration.
5. Mock modes are allowed during development but must mirror the real response shape exactly.

## Migration Order
1. **Networking layer** — ApiService, services, request/response models
2. **Repositories** (if any) — adapters between services and providers
3. **Providers** — state management (only if model shapes change)
4. **Screens/UI** — only if model shapes changed (avoid unless necessary)

## What NOT to Modify
- Do **not** modify UI screens unless a compile error forces it.
- Do **not** modify navigation or route logic.
- Do **not** modify business logic in providers beyond updating type references.
- Do **not** delete existing mock data — keep it for offline development.
