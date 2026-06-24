# API Migration Report

**Generated:** June 23, 2026 (Revised)
**Project:** wslny-frontend
**OpenAPI Spec:** assets/api/openapi.json
**Source of Truth:** OpenAPI specification

---

## Executive Summary

The Flutter project has already completed **Phase 1 (Critical)** migration — Dio is in use, auth/route paths use `/api/v1/`, and core models are updated. Remaining work covers **Phases 3-5**: creating UserService, TransitService, Routing enhancement endpoints, and adding header-based routing.

---

## 1. Current API Services Analysis

### 1.1 ApiService (`lib/services/api_service.dart`)
- **Type:** Base HTTP client
- **Client:** ✅ **Dio** (migrated)
- **Status:** ✅ Operational
- **Remaining:** Add `requireHeader` parameter to inject `X-Module: Auth/Routing/Transit/User` header

### 1.2 AuthService (`lib/services/auth_service.dart`)
- **Status:** ✅ Fully migrated
- **Endpoints implemented:**
  - `POST /api/v1/auth/login` ✅
  - `POST /api/v1/auth/register` ✅
  - `POST /api/v1/auth/google-login` ✅
  - `GET /api/v1/auth/profile` ✅
- **Missing (Phase 2):**
  - `PUT /api/v1/auth/profile`
  - `POST /api/v1/auth/change-password`
  - `POST /api/v1/auth/refresh`

### 1.3 RouteService (`lib/services/route_service.dart`)
- **Status:** ✅ Partially migrated
- **Endpoints implemented:**
  - `POST /api/v1/route` ✅ (text + coordinates)
- **Missing endpoints:**
  - `GET /api/v1/route/history`
  - `POST /api/v1/routes/alternatives`
  - `POST /api/v1/routes/feedback`
  - `GET /api/v1/routes/metadata`
  - `POST /api/v1/routes/search`
  - `POST /api/v1/routes/search/confirm`

### 1.4 Missing Services

| Service | File | Status |
|---------|------|--------|
| **UserService** | `lib/services/user_service.dart` | ❌ Not created |
| **TransitService** | `lib/services/transit_service.dart` | ❌ Not created |

### 1.5 Non-Backend Services (No Changes Required)
- `ChatStorageService` — local SharedPreferences
- `GeocodingService` — external Nominatim API
- `LocationService` — device Geolocator
- `OsrmService` — external OSRM API
- `OverpassService` — external Overpass/Google Places

---

## 2. Endpoint Mapping: Current → OpenAPI

### 2.1 Auth Endpoints

| Current Endpoint | OpenAPI Endpoint | Method | Status |
|-----------------|-----------------|--------|--------|
| `/api/v1/auth/login` | `/api/v1/auth/login` | POST | ✅ Done |
| `/api/v1/auth/register` | `/api/v1/auth/register` | POST | ✅ Done |
| `/api/v1/auth/google-login` | `/api/v1/auth/google-login` | POST | ✅ Done |
| `/api/v1/auth/profile` | `/api/v1/auth/profile` | GET | ✅ Done |
| — | `/api/v1/auth/profile` | PUT | ❌ Missing |
| — | `/api/v1/auth/change-password` | POST | ❌ Missing |
| — | `/api/v1/auth/refresh` | POST | ❌ Missing |

### 2.2 Routing Endpoints

| Current Endpoint | OpenAPI Endpoint | Method | Status |
|-----------------|-----------------|--------|--------|
| `/api/v1/route` | `/api/v1/route` | POST | ✅ Done |
| — | `/api/v1/route/history` | GET | ❌ Missing |
| — | `/api/v1/routes/alternatives` | POST | ❌ Missing |
| — | `/api/v1/routes/feedback` | POST | ❌ Missing |
| — | `/api/v1/routes/metadata` | GET | ❌ Missing |
| — | `/api/v1/routes/search` | POST | ❌ Missing |
| — | `/api/v1/routes/search/confirm` | POST | ❌ Missing |

### 2.3 Transit Endpoints

| Endpoint | Method | Status |
|----------|--------|--------|
| `/api/v1/lines` | GET | ❌ Missing |
| `/api/v1/lines/{route_id}` | GET | ❌ Missing |
| `/api/v1/stops/{stop_id}` | GET | ❌ Missing |
| `/api/v1/stops/nearby` | GET | ❌ Missing |

### 2.4 User Endpoints

| Endpoint | Method | Status |
|----------|--------|--------|
| `/api/v1/user/favorites` | GET | ❌ Missing |
| `/api/v1/user/favorites` | POST | ❌ Missing |
| `/api/v1/user/favorites/{id}` | DELETE | ❌ Missing |
| `/api/v1/user/preferences` | GET | ❌ Missing |
| `/api/v1/user/preferences` | PUT | ❌ Missing |
| `/api/v1/user/saved-locations` | GET | ❌ Missing |
| `/api/v1/user/saved-locations` | POST | ❌ Missing |
| `/api/v1/user/saved-locations/{id}` | PUT | ❌ Missing |
| `/api/v1/user/saved-locations/{id}` | DELETE | ❌ Missing |

---

## 3. Request/Response Model Status

### 3.1 Models Already Migrated ✅

| Model | File | Status |
|-------|------|--------|
| `AuthUser` | `auth_models.dart` | ✅ Matches spec |
| `LoginRequest` | `auth_models.dart` | ✅ Matches spec |
| `RegisterRequest` | `auth_models.dart` | ✅ Has `role` field |
| `GoogleLoginRequest` | `auth_models.dart` | ✅ Matches spec |
| `ChangePasswordRequest` | `auth_models.dart` | ✅ Matches spec |
| `UpdateProfileRequest` | `auth_models.dart` | ✅ Matches spec |
| `TokenRefresh` | `auth_models.dart` | ✅ Matches spec |
| `MessageResponse` | `auth_models.dart` | ✅ Matches spec |
| `AuthSuccessResponse` | `auth_models.dart` | ✅ Matches spec |
| `Coordinate` | `coordinate.dart` | ✅ Matches spec |
| `RouteFilter` | `route_models.dart` | ✅ Compatible |
| `RouteRequest` | `route_models.dart` | ✅ Has origin/destination/currentLocation |
| `RouteResponse` | `route_models.dart` | ✅ Has nullable route |
| `RouteInfo` | `route_models.dart` | ✅ Nullable estimatedFare/walkDistanceMeters |
| `RouteSegment` | `route_models.dart` | ✅ Has optional polyline |
| `RouteLocation` | `route_models.dart` | ✅ Compatible |
| `RouteQuery` | `route_models.dart` | ✅ Compatible |
| `UserModel` | `user_model.dart` | ✅ Kept for extended profile |
| `TypeEnum` | `user_request_models.dart` | ✅ Matches spec |
| `CreateFavoriteRouteRequest` | `user_request_models.dart` | ✅ Exists (may need review) |
| `CreateSavedLocationRequest` | `user_request_models.dart` | ✅ Exists |
| `UpdateSavedLocationRequest` | `user_request_models.dart` | ✅ Exists |
| `UpdatePreferencesRequest` | `user_request_models.dart` | ✅ Exists |

### 3.2 Models Still Needed ❌

| Model | Spec Schema | Priority |
|-------|-------------|----------|
| `RouteAlternativesRequest` | `#/components/schemas/RouteAlternativesRequest` | Medium |
| `RouteFeedbackRequest` | `#/components/schemas/RouteFeedbackRequest` | Medium |
| `RouteHistoryItem` | inline (array) | Low |
| `RouteMetadataResponse` | `#/components/schemas/RouteMetadataResponse` | Low |
| `RouteSearchRequest` | `#/components/schemas/RouteSearchRequest` | Low |
| `RouteSearchResponse` | `#/components/schemas/RouteSearchResponse` | Low |
| `RouteSearchConfirmRequest` | `#/components/schemas/RouteSearchConfirmRequest` | Low |
| `RouteSuccessResponse` | `#/components/schemas/RouteSuccessResponse` | Medium |
| `Line` | inline (Transit) | Medium |
| `LineDetails` | inline (Transit) | Medium |
| `StopDetails` | inline (Transit) | Medium |
| `FavoriteRoute` (response) | inline (User) | Medium |
| `UserPreferences` (response) | `#/components/schemas/UserPreferences` | Medium |
| `SavedLocation` (response) | inline (User) | Medium |

---

## 4. Required Headers

Per `API_MIGRATION_RULES.md`, the `ApiService` must inject an `X-Module` header:

| Header Value | Endpoints |
|-------------|-----------|
| `Auth` | `/api/v1/auth/*` |
| `Routing` | `/api/v1/route*` |
| `Transit` | `/api/v1/lines*`, `/api/v1/stops*` |
| `User` | `/api/v1/user/*` |

All endpoints also require `Authorization: Bearer <token>` (except login, register, google-login which skip auth).

---

## 5. Remaining Work Summary

### Phase 2: Auth Enhancements
1. Add `PUT /api/v1/auth/profile` to AuthService
2. Add `POST /api/v1/auth/change-password` to AuthService
3. Add `POST /api/v1/auth/refresh` to AuthService
4. Wire refresh token logic into ApiService interceptor

### Phase 3: User Service
1. Create `UserService` with all 9 user endpoints
2. Map existing `user_request_models.dart` models to service calls
3. Add `FavoriteRoute`, `UserPreferences`, `SavedLocation` response models

### Phase 4: Routing Enhancements
1. Add 6 missing routing endpoints to RouteService
2. Create missing route request/response models
3. Add header-based routing param to ApiService

### Phase 5: Transit Service
1. Create `TransitService` with 4 transit endpoints
2. Create Line/Stop models
3. Add header-based routing param

### Phase 6: ApiService Header Support
1. Add optional `header` parameter to all HTTP methods
2. Map header names (`Auth`, `Routing`, `Transit`, `User`) to `X-Module` header values
3. Register `assets/api/` in `pubspec.yaml`

---

## 6. Breaking Changes Already Applied ✅

- **Dio migration** — ApiService now uses Dio
- **Path prefix** — all paths use `/api/v1/`
- **RouteRequest** — uses Coordinate objects for origin/destination/currentLocation
- **RouteSegment** — supports optional polyline
- **Nullable fields** — estimatedFare, walkDistanceMeters, route are nullable
- **Auth models** — AuthUser, ChangePasswordRequest, UpdateProfileRequest, TokenRefresh, MessageResponse all exist
- **User request models** — CreateFavoriteRouteRequest, CreateSavedLocationRequest, etc. all exist

---

## 7. Next Steps

1. **Add header support to ApiService** — `X-Module` header injection
2. **Create UserService** — all 9 user endpoints
3. **Create TransitService** — all 4 transit endpoints
4. **Add missing auth endpoints** — PUT profile, change-password, refresh
5. **Add missing routing endpoints** — history, alternatives, feedback, metadata, search, search/confirm
6. **Create missing models** for items in section 3.2
7. **Build and fix** compile errors
8. **Validate** all calls against openapi.json
