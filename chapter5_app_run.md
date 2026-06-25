# Wslny Mobile App — App Run Guide

The **Wslny Mobile App** is the commuter-facing application for the
Wslny public-transit platform serving Cairo, Egypt. It lets users
plan multi-modal routes using a combination of metro, bus, microbus,
and walking — driven by a Django REST API backend.

This guide walks through every screen in the mobile app from the
user's point of view. Every screen has a **Fig 5.X** reference and
a description of what the screenshot should contain so it can be
captured or replaced.

---

## 5.1 Sign-In Screen

The Sign-In screen is the entry point to the app for returning users.
It presents a clean white card with the Wslny brand identity — a teal
translate icon at the top — followed by **Email** and **Password**
text fields, a "Remember Me" checkbox, a **Sign In** button, a
divider with "or", and a **Continue with Google** button. Below the
form, a row reads "Don't have an account? Sign Up" which navigates
to the Registration screen. A "Forgot Password?" link is visible but
routes to a placeholder in this version.

Error handling surfaces user-friendly messages for invalid
credentials, network timeouts, and server errors via a SnackBar at
the bottom. On successful authentication, the app stores JWT tokens
locally and redirects to the Main Layout.

**Fig 5.1 Sign-In screen**

> **📸 Image description:** 390×844 iPhone frame. Top: teal rounded
> icon with translate symbol. Heading "Welcome Back" with subtitle
> "Sign in to your account". Email and Password fields (password has
> eye-toggle). "Remember Me" checkbox. Full-width teal **Sign In**
> button. "or" divider. Google sign-in button. Bottom: "Don't have
> an account? Sign Up" link.

---

## 5.2 Registration Screen

The Registration screen is reached by tapping "Sign Up" from the
Sign-In screen. It shows a scrollable form with eight inputs: First
Name, Last Name, Email, Phone (optional), Gender (Male/Female radio
buttons), Address (optional), Password, and Confirm Password. A
checkbox below the form requires agreement to the Terms of Service
and Privacy Policy before the **Sign Up** button becomes actionable.
A Google sign-up option mirrors the sign-in flow.

Validation enforces: name minimum 2 characters, email regex format,
password minimum 8 characters, and password-confirm match. On
successful registration the user is automatically logged in and
navigated to the Main Layout.

**Fig 5.2 Registration screen**

> **📸 Image description:** 390×844 iPhone frame. Scrollable form
> with First Name and Last Name side-by-side, then Email, Phone,
> Gender radio (Male selected), Address, Password, Confirm Password
> fields. Terms checkbox. Teal **Sign Up** button. Google button.
> Bottom: "Already have an account? Sign In" link.

---

## 5.3 Main Layout — Bottom Navigation

After authentication, the app lands on the **Main Layout**, which
provides four tabs via a custom bottom navigation bar:

| Index | Tab | Screen | Icon |
|---|---|---|---|
| 0 | Home | Map Home Page | `home` |
| 1 | Favorites | Favorites Page | `favorite` |
| 2 | History | History Page | `history` |
| 3 | Profile | Profile Page | `person` |

The bottom nav bar uses a rounded container with shadow and is
forced left-to-right even when the app language is Arabic. Tapping
a tab switches the entire body content immediately (pages are not
cached, so each tab reloads fresh data on every switch).

**Fig 5.3 Main Layout — Home tab active**

> **📸 Image description:** 390×844 iPhone frame. Full-screen Google
> Map of Cairo with a search bar at the top, a bottom control panel
> showing Start/End pick mode and "Get Route" button. Bottom nav bar
> with Home (filled), Favorites, History, Profile icons.

---

## 5.4 Map Home Page

The **Map Home Page** is the default tab and the primary screen of
the app. It displays a full-screen Google Map centered on Cairo
(30.0444, 31.2357). The user interacts with the map in two modes
controlled by a `SegmentedButton` at the bottom:

- **Start mode (green):** Tap a location on the map to set the
  origin point. A green marker appears, and the address is
  reverse-geocoded via Nominatim (OpenStreetMap) and displayed.
- **End mode (red):** Tap a location to set the destination. A red
  marker appears.

A **Search Bar** at the top lets the user type a place name. Results
are fetched from Nominatim and displayed in a bottom sheet with rich
icons categorised by place type (restaurant, hotel, school, etc.).
Selecting a result sets it as the active point (start or end).

The **Control Panel** at the bottom provides:

- A `SegmentedButton` to toggle between picking Start or End
- Address labels for both points
- "Me → Start" / "Me → End" buttons to use the device's GPS
  location as one of the points
- **Clear** button to reset both points
- **Get Route** button (enabled when the end point is set)

When the user taps "Get Route", the app calls
`RouteService.getRouteByCoordinates()` which sends a request to the
backend. For each returned segment, the app fetches realistic driving
path polylines from OSRM (Open Source Routing Machine). The combined
result is passed to the **Route Results Page**.

The panel also has a collapsed mode (thin bar) when no points are
active, and expands automatically when points are set. A **Chat**
button in the search area navigates to the Chatbot Page.

Small cards at the bottom of the map show recent search suggestions.

**Fig 5.4.1 Map Home Page — default state**

> **📸 Image description:** 390×844 iPhone frame. Full-screen Google
> Map centred on Cairo. Top: search bar with placeholder text and
> chat icon button. Bottom: collapsed thin bar with "Tap map to set
> start point" hint. Bottom nav visible.

**Fig 5.4.2 Map Home Page — start and end points set**

> **📸 Image description:** 390×844 iPhone frame. Google Map with
> green marker (Start) and red marker (End), connected by a purple
> route polyline. Expanded control panel showing start address, end
> address, SegmentedButton (Start selected), "Me → Start" / "Me →
> End" buttons, **Get Route** teal button.

**Fig 5.4.3 Map Home Page — search results**

> **📸 Image description:** 390×844 iPhone frame. Map blurred in
> background. Bottom sheet with search results list: place names
> with type icons (restaurant, hotel, school, etc.) and address
> subtitles. Search bar at top with query text.

---

## 5.5 Route Results Page

The Route Results Page opens after the user taps "Get Route" and the
backend returns a multi-modal route plan. It receives a `RouteResponse`
object and displays:

### Summary Card
A card at the top shows:
- Route title: "from: [origin] to: [destination]"
- Four metrics in a row: Duration, Distance, Fare (EGP), Walking
  distance

### Map View
An interactive Google Map below the summary displays:
- **Green marker** — Start point
- **Red marker** — End point
- **Blue markers** — Transfer points between segments
- **Violet markers** — Metro stations (fetched from Overpass API)
- **Polylines** — Route path per segment, colour-coded:
  - Orange dashed — Walking
  - Blue solid — Bus
  - Green solid — Microbus
  - Purple solid — Metro / Subway
  - Grey solid — Default / Unknown

Each segment's polyline is generated by OSRM for realistic road
paths. If OSRM fails, a straight-line fallback is used.

### Step-by-Step Directions
A scrollable list below the map shows each segment with:
- Coloured circle avatar with transport method icon
- Title: "Bus from [A] to [B]" / "Walk from [A] to [B]" / etc.
- Subtitle: duration and distance (e.g. "15 min • 3.2 km")
- Stop count if applicable (e.g. "4 stops")
- Tapping a segment highlights it and focuses the map camera on
  that segment's bounds

### Save to Favorites
A heart icon in the app bar toggles saving the route to local
favorites (stored in SharedPreferences via `ChatStorageService`).
A SnackBar confirms save or removal.

### Fit All Segments
A zoom-to-fit icon resets the map camera to show the entire route.

**Fig 5.5.1 Route Results Page — full view**

> **📸 Image description:** 390×844 iPhone frame. AppBar with "Route
> Details", heart icon and zoom icon. Summary card with route title
> and 4 metrics (Duration, Distance, Fare, Walking). Google Map
> showing green/red markers, blue transfer markers, and colour-coded
> polylines. Below: "Step-by-step Directions" header with list of
> transport segments.

**Fig 5.5.2 Route Results Page — segment selected**

> **📸 Image description:** 390×844 iPhone frame. One segment in the
> directions list highlighted with teal border and background. Map
> camera focused on that segment's start-to-end bounds.

---

## 5.6 Chatbot Page

The Chatbot Page is a full-screen conversational interface accessed
from the Map Home Page's chat icon button. It lets users request
routes using natural language (typed or spoken).

### Speech-to-Text
A microphone button in the input bar activates device speech
recognition. The app uses the `speech_to_text` package with Arabic
(`ar_SA`) locale support, so users can speak queries like
"من مصر الجديدة إلى وسط البلد".

### Chat Interface
- **Welcome message:** Shown on first launch with example queries
  in both Arabic and English.
- **User bubbles:** Right-aligned, primary-coloured.
- **Bot bubbles:** Left-aligned, grey background.
- **Route bubbles:** Rich card preview showing duration and fare,
  tap to open Route Results Page.
- **Confirmation bubble:** Yes/No prompt after a route is found,
  with a favourite toggle.

### Route Request Flow
1. User types or speaks a destination query
2. App calls `RouteService.getRouteByText()` with the text and
   current GPS location
3. A filter selection prompt appears (Optimal / Fastest / Cheapest /
   Bus Only / Microbus Only / Metro Only)
4. Backend returns a `RouteResponse`
5. A route preview card is displayed; user taps to view details
   on the Route Results Page

### Chat History
All messages are persisted locally via `ChatStorageService`
(SharedPreferences) and restored on next visit.

**Fig 5.6.1 Chatbot Page — welcome state**

> **📸 Image description:** 390×844 iPhone frame. AppBar with "Chat"
> title. Chat area: bot bubble with welcome message and example
> queries. Bottom input bar with text field, microphone button, send
> button.

**Fig 5.6.2 Chatbot Page — active conversation**

> **📸 Image description:** 390×844 iPhone frame. Chat area with
> multiple user bubbles (right, teal) and bot bubbles (left, grey).
> One route bubble showing duration, distance, fare with "View
> Details" tap target. Input bar with typed query.

**Fig 5.6.3 Chatbot Page — filter selection**

> **📸 Image description:** 390×844 iPhone frame. Filter selection
> chips or bottom sheet showing: Optimal, Fastest, Cheapest, Bus
> Only, Microbus Only, Metro Only options.

---

## 5.7 Favorites Page

The Favorites Page (Tab 1 in Bottom Nav) lists the user's saved
routes loaded from local storage (`ChatStorageService`).

### Features
- **Search bar** at the top to filter favourites by custom name,
  origin, or destination
- **Card list:** Each saved route appears as a card showing:
  - Custom name (e.g. "from: Zamalek to: Maadi")
  - From → To location names
  - Duration, fare, distance metrics
  - **Use Route** button -> navigates to Route Results Page
  - Popup menu (three dots) with **Delete** option
- **Empty state:** Friendly icon and "No saved routes yet" message
  when the list is empty

**Fig 5.7.1 Favorites Page — with saved routes**

> **📸 Image description:** 390×844 iPhone frame. App area with
> "Favorites" header. Search bar. Vertical card list: each card has
> route name, from/to labels, duration/fare/distance row, teal "Use
> Route" button, and three-dot menu on the right.

**Fig 5.7.2 Favorites Page — empty state**

> **📸 Image description:** 390×844 iPhone frame. Centred empty
> illustration (heart icon), "No saved routes yet" message, subtitle
> "Routes you save will appear here."

---

## 5.8 History Page

The History Page (Tab 2 in Bottom Nav) displays the user's past
route requests fetched from the backend (`GET /api/v1/route/history`).

### Features
- **Search bar** to filter by origin name, destination name, or
  input text
- **Card list:** Each history entry shows:
  - From → To location names
  - Input text that was searched
  - Status (e.g. completed)
  - Duration, fare, distance metrics
  - **View Route** button -> re-fetches the route by text and
    navigates to Route Results Page with a loading spinner
- **Empty state:** Icon and "No route history yet" message

**Fig 5.8.1 History Page — with items**

> **📸 Image description:** 390×844 iPhone frame. App area with
> "History" header. Search bar. Vertical card list: each card has
> from/to names, status badge, duration/fare/distance row, teal
> "View Route" button.

**Fig 5.8.2 History Page — empty state**

> **📸 Image description:** 390×844 iPhone frame. Centred empty
> illustration (history icon), "No route history yet" message,
> subtitle "Your past routes will appear here."

---

## 5.9 Profile Page

The Profile Page (Tab 3 in Bottom Nav) lets the user manage their
account and app preferences.

### Header Card
- Circular avatar icon with teal background (first letter or default
  person icon)
- User's full name (from `AuthProvider.user`)
- Email address

### Quick Settings Card
- **Language** row — tapping opens a modal bottom sheet with two
  options:
  - English (US) — checkmark when selected
  - العربية (Arabic) — checkmark when selected
  Selecting a language immediately updates the app-wide locale and
  persists the choice to SharedPreferences via `LanguageProvider`.
- **Dark Mode** row — a Switch toggle that switches between light
  and dark theme, persisted via `ThemeProvider`.

### Sign Out Button
A red-outlined button at the bottom calls `AuthProvider.signOut()`,
clears stored tokens, and navigates back to the Sign-In screen with
a cleared navigation stack.

**Fig 5.9.1 Profile Page**

> **📸 Image description:** 390×844 iPhone frame. "Profile" header
> aligned left. Header card with large teal circle avatar, user name
> "Ahmed Hassan", email below. "Quick Settings" card with Language
> row (chevron right) and Dark Mode row (switch off). Red-outlined
> "Sign Out" button at the bottom.

**Fig 5.9.2 Language picker bottom sheet**

> **📸 Image description:** 390×844 iPhone frame. Bottom sheet with
> drag handle, "Select Language" title, two rows: "English" with
> subtitle "English" (selected, with teal checkmark) and "العربية"
> with subtitle "Arabic". Background is dimmed.

**Fig 5.9.3 Profile Page — dark mode**

> **📸 Image description:** 390×844 iPhone frame in dark theme.
> Dark backgrounds throughout: scaffold (#0F1A1C), cards with dark
> teal surfaces. Same layout with toggled Dark Mode switch on.

---

## 5.10 Language Selection Screen

The Language Selection screen appears only when the user is already
authenticated and navigates back to language settings (e.g. from
the Profile page flow). It is **not shown on first launch** —
first-time users go directly to Sign-In.

The screen displays the app icon (teal translate icon), a title
"Choose Language", a subtitle "Select your preferred language", and
two Language Button widgets: English (US) and Arabic (EG). Selecting
a language navigates to the Sign-In screen if unauthenticated, or
pops back if already authenticated.

**Fig 5.10 Language Selection screen**

> **📸 Image description:** 390×844 iPhone frame. Centred layout:
> teal rounded icon with translate symbol, "Choose Language" heading,
> "Select your preferred language" subtitle. Two outlined rows:
> "English (US)" with chevron, "العربية (EG)" with chevron.

---

## 5.11 Sign-Out

Sign-out is initiated from the **Profile Page** by tapping the red
"Sign Out" button. The action:

1. Calls `AuthProvider.signOut()` which clears the stored JWT
   tokens and user data
2. Navigates to the Sign-In screen using
   `Navigator.pushNamedAndRemoveUntil` to clear the entire
   navigation stack
3. The user is returned to the Sign-In screen and must authenticate
   again to access the app

---

## 5.12 Navigation Flow Summary

```
App Launch
    │
    ▼
InitScreen ──► (checks stored JWT)
    │
    ├── Authenticated? ──► MainLayout (4 tabs)
    │
    └── Not Authenticated? ──► SignInScreen
                                  │
                                  ├── Sign In (email/password / Google)
                                  │       └── Success ──► MainLayout
                                  │
                                  └── "Sign Up" ──► RegistrationScreen
                                          └── Success ──► MainLayout

MainLayout
    │
    ├── [Home] MapHomePage
    │       ├── Get Route ──► RouteResultsPage
    │       │       └── Save to Favorites
    │       └── Chat button ──► ChatbotPage
    │               └── View Route ──► RouteResultsPage
    │
    ├── [Favorites] FavoritesPage
    │       └── Use Route ──► RouteResultsPage
    │
    ├── [History] HistoryPage
    │       └── View Route ──► RouteResultsPage
    │
    └── [Profile] ProfilePage
            ├── Language picker (bottom sheet, in-place)
            ├── Dark Mode toggle (in-place)
            └── Sign Out ──► SignInScreen
```

---

## 5.13 Common UI Behaviour

Across every page the app uses a small set of consistent patterns:

- **Loading states:** `CircularProgressIndicator` centred on the
  screen during data fetches (auth, history, route computation).
- **Error states:** SnackBar at the bottom with red/orange
  background for errors (network failures, invalid credentials,
  route fetch failures).
- **Success states:** SnackBar with green background for
  confirmation (sign-in success, route saved, route removed).
- **Empty states:** Friendly centred illustration with icon,
  heading, and subtitle text for empty lists (favorites, history).
- **Navigation:** Standard Flutter push/pop patterns; the app
  maintains a clear navigation stack with no back-stack from
  MainLayout to the auth screens.
- **RTL support:** The entire app respects the selected language's
  text direction. Arabic users see right-to-left layout. The bottom
  nav bar is forced left-to-right to maintain consistent icon/text
  order.

---

## 5.14 App Theme

The app uses Material 3 with a **teal seed colour** (`#4DB6AC`):

- **Light theme:** White fill, teal primary, rounded inputs and
  cards, subtle shadows.
- **Dark theme:** Dark teal scaffold (`#0F1A1C`), dark surfaces,
  teal accents.

The theme can be toggled between Light, Dark, and System mode via
the Dark Mode switch on the Profile Page. The selection is persisted
across sessions.

---

## 5.15 Troubleshooting (Quick Reference)

- **I can't sign in** → Check your email and password. If forgotten,
  the "Forgot Password" link is a placeholder — contact support.
- **The map doesn't load** → Ensure you have an internet connection.
  The Google Maps API key must be set in `.env`. On web, the Google
  Maps JS script is loaded automatically.
- **Route search returns no results** → Try different phrasing or
  use the map to set points manually. Some areas may not be covered
  by the routing engine.
- **Speech recognition doesn't work** → Ensure microphone permission
  is granted. Arabic speech recognition requires Arabic locale
  support on the device.
- **Favourites not showing** → Favourites are stored locally. If you
  clear app data, saved routes are lost. Switch tabs to refresh.
- **History is empty** → History is fetched from the server. Ensure
  you have an internet connection and have made previous route
  requests.

---

_End of guide. Last updated: 2026-06-25._
