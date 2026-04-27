# Forge Implementation Tracker

User stories and tasks, organized by priority. Status: **TODO** · **IN PROGRESS** · **DONE** · **BLOCKED**

---

## Phase 1: Core Library

### CORE-001 — Extract Forge Base from Hoard
Extract `core/` directory from hoard. `Hoard::` → `Forge::` namespace, all files copied.

**Status:** DONE ✓
**Prerequisites:** None

**Files to extract:**
- [ ] `app/forge.rb` — main require, `Forge` namespace
- [ ] `app/base/process.rb`
- [ ] `app/base/entity.rb`
- [ ] `app/base/user.rb`
- [ ] `app/base/scriptable.rb`
- [ ] `app/base/widgetable.rb`
- [ ] `app/base/script.rb`
- [ ] `app/base/widget.rb`
- [ ] `app/utils/cooldown.rb`
- [ ] `app/utils/delayer.rb`
- [ ] `app/utils/tweenie.rb`
- [ ] `app/utils/scheduler.rb`
- [ ] `app/utils/recyclable_pool.rb`
- [ ] `app/utils/stat.rb`
- [ ] `app/utils/l_point.rb`
- [ ] `app/utils/scaler.rb`
- [ ] `app/utils/layer.rb`
- [ ] `app/utils/utils.rb`
- [ ] `app/utils/serializable.rb`
- [ ] `app/utils/const.rb`
- [ ] `app/phys/velocity.rb`
- [ ] `app/phys/velocity_array.rb`
- [ ] `app/ui/theme.rb`
- [ ] `app/ui/context.rb`
- [ ] `app/ui/component.rb`
- [ ] `app/ui/button.rb`
- [ ] `app/ui/label.rb`
- [ ] `main.rb` — minimal entry point
- [ ] `packages.rb` — auto-generated stub
- [ ] `packages.lock.json` — empty
- [ ] `Gemfile`
- [ ] `api_key.rb.example` — template with `YOUR_API_KEY` placeholder
- [ ] `.gitignore` — ignores `api_key.rb`

---

### CORE-002 — Package Manager
In-game package manager. `app/package_manager.rb`.

**Status:** DONE ✓
**Prerequisites:** CORE-001, API-002

**Tasks:**
- [ ] `Forge.add_package(name, version:)` — fetch manifest, download ZIP, extract
- [ ] `Forge.remove_package(name)` — remove directory, update lock
- [ ] `Forge.update_packages` — check newer versions
- [ ] `Forge.list_installed` — read lock file
- [ ] `Forge.search(query)` — proxy to API
- [ ] `Forge.publish_package(...)` — with `can_publish` check
- [ ] Dependency resolution (topological sort, semver)
- [ ] HTTP client using `Forge::API_KEY` for all calls

---

### CORE-003 — Test Core in DragonRuby
Verify the base library runs in DragonRuby.

**Status:** TODO
**Prerequisites:** CORE-001

**Tasks:**
- [ ] Open `core/` in DragonRuby — empty game runs
- [ ] `Forge.tick(args)` updates Process loop
- [ ] `Forge.config.game_class` works
- [ ] `Forge::Entity` instantiates correctly

---

## Phase 2: API Key System

### API-001 — ApiKey Model & Migration
Database model for API key authentication.

**Status:** DONE ✓
**Prerequisites:** None

**Tasks:**
- [ ] `ApiKey` migration: `key`, `user_id` (optional), `name`, `download_count`, `publish_count`
- [ ] `ApiKey` model with `anonymous?`, `can_publish?`, `display_name`
- [ ] `User` has_many :api_keys
- [ ] SecureRandom hex key generation on create
- [ ] Unique index on `key`

---

### API-002 — Anonymous User Flow
Automatic anonymous account creation on download.

**Status:** DONE ✓
**Prerequisites:** API-001

**Tasks:**
- [ ] `User` has `role: :anonymous` option
- [ ] Anonymous user auto-created if no session
- [ ] `ApiKey` created and tied to anonymous user on download

---

### API-003 — Auth Endpoints
API endpoints for key verification and user info.

**Status:** DONE ✓
**Prerequisites:** API-001

**Tasks:**
- [ ] `POST /api/auth/verify` — validate key, return `{user_id, username, anonymous, can_publish}`
- [ ] `GET /api/me` — return user info + api_keys list from `Authorization: Bearer <key>` header
- [ ] `401` for invalid/missing keys
- [ ] `can_publish: false` for anonymous keys

---

### API-004 — Publish Permission Enforcement
Server-side block on anonymous publishing.

**Status:** DONE ✓
**Prerequisites:** API-001, API-003

**Tasks:**
- [ ] `POST /api/packages` checks `ApiKey#can_publish?` before creating version
- [ ] `403 Forbidden` response for anonymous keys with message directing to website
- [ ] `publish_count` incremented only on successful publish

---

## Phase 3: Website Downloads

### DL-001 — New Project Page
The "download base library" page.

**Status:** DONE ✓
**Prerequisites:** API-002

**Tasks:**
- [ ] `GET /new` renders download page
- [ ] Optional project name field
- [ ] "Download Forge Base Library" button

---

### DL-002 — Download Zip Generation
Generate and serve the zip with embedded API key.

**Status:** DONE ✓
**Prerequisites:** DL-001

**Tasks:**
- [ ] `GET /new/download` action
- [ ] Find or create `ApiKey` (session user or anonymous)
- [ ] Copy `core/` to temp dir
- [ ] Substitute `YOUR_API_KEY` with real key in `api_key.rb`
- [ ] Optional project name rename in zip
- [ ] Zip and stream download
- [ ] Increment `download_count` on `ApiKey`

---

### DL-003 — Package Download Count
Track download counts on package versions.

**Status:** DONE ✓
**Prerequisites:** API-002

**Tasks:**
- [ ] `GET /api/packages/:name/versions/:version/download` endpoint
- [ ] Increment `PackageVersion#download_count` on each download

---

## Phase 4: Browse & Package Pages

### BROWSE-001 — Package Listing
Browse all packages with search and filters.

**Status:** DONE ✓
**Prerequisites:** None

**Tasks:**
- [x] `GET /packages` — list all packages
- [x] Search by name/description
- [x] Filter by tags
- [x] Package cards: name, version, author, description, tags

---

### BROWSE-002 — Package Detail Page
Package info, code viewer, install instructions.

**Status:** DONE ✓
**Prerequisites:** BROWSE-001

**Tasks:**
- [ ] `GET /packages/:name` — detail page
- [ ] Version selector dropdown
- [ ] Scripts section with file list
- [ ] Widgets section with file list
- [ ] Dependencies section
- [ ] Tags section
- [ ] Author info
- [ ] "Add to Project" button → generates require snippet
- [ ] "Copy install snippet" → `Forge.add_package("...")`
- [ ] Install instructions block

---

### BROWSE-003 — Code Viewer
Syntax-highlighted source code display.

**Status:** DONE ✓
**Prerequisites:** BROWSE-002

**Tasks:**
- [ ] File tree navigation
- [ ] Syntax-highlighted Ruby display
- [ ] File contents served from stored ZIP or DB
- [ ] `GET /api/packages/:name/versions/:version/files` — file listing
- [ ] `GET /api/packages/:name/versions/:version/files/:path` — file contents

---

## Phase 5: Publishing

### PUB-001 — Publish Form
Form-based package publishing.

**Status:** DONE ✓
**Prerequisites:** API-004

**Tasks:**
- [ ] `GET /publish` — publish form (requires auth)
- [ ] Fields: package name, version, description, tags, scripts[], widgets[], assets[], dependencies[]
- [ ] Manifest.json auto-generated from form
- [ ] Validation: name format, semver version, no duplicate version

---

### PUB-002 — ZIP Upload Publishing
Publish packages via ZIP upload.

**Status:** DONE ✓
**Prerequisites:** PUB-001

**Tasks:**
- [ ] ZIP upload accepts packaged directory
- [ ] Auto-parses `manifest.json` from ZIP
- [ ] Scripts[] / Widgets[] file list from ZIP contents
- [ ] Validates scripts/widgets match uploaded files

---

### PUB-003 — Package Storage
Store and serve package ZIP files.

**Status:** DONE ✓
**Prerequisites:** None

**Tasks:**
- [x] `PackageStorageService` for local filesystem storage
- [x] ZIP files stored in `storage/packages/{name}/{version}.zip`
- [x] Download endpoint uses storage service
- [x] Upload endpoint for direct ZIP upload (with auth)
- [x] Delete file endpoint
- [x] Storage info endpoint

---

## Phase 6: User Accounts

### AUTH-001 — User Registration & Login
Account creation and session management.

**Status:** DONE ✓
**Prerequisites:** None

**Tasks:**
- [x] `GET /register` — registration form
- [x] `POST /api/auth/register` — create account
- [x] `GET /login` — login form
- [x] `POST /api/auth/login` — authenticate
- [x] `DELETE /api/auth/logout` — end session
- [x] Password hashing (bcrypt)
- [x] Session cookies
- [x] Error messages for invalid credentials

---

### AUTH-002 — Link Anonymous Keys
Claim anonymous keys after registering.

**Status:** DONE ✓
**Prerequisites:** AUTH-001, API-001

**Tasks:**
- [x] Account settings page
- [x] "Your API Keys" section
- [x] List all keys tied to account
- [x] Claim anonymous key by entering key
- [x] Transfer `user_id` from anonymous to registered account
- [x] List, rename, revoke keys

---

## Phase 7: Package Extraction (Hoard → Packages)

### PKG-001 — LDTK Parser Package
`ldtk_parser` package. The full LDTK parser + LdtkLoaderScript + sample.

**Status:** DONE ✓
**Prerequisites:** CORE-001

**Files:** All 17 `hoard/ldtk/` files + `scripts/ldtk_entity_script.rb` + `scripts/move_to_neighbour_script.rb` + `scripts/move_to_destination_script.rb`

**Tasks:**
- [x] Namespace: `Hoard::Ldtk::` → `Forge::Ldtk::`
- [x] `manifest.json` with scripts[], dependencies: []
- [x] LDTK Loader Script + sample
- [x] All 17 LDTK classes: Root, Level, World, LayerInstance, EntityInstance, etc.

---

### PKG-002 — Movement Scripts
Extract all movement-related scripts.

**Status:** DONE ✓
**Prerequisites:** CORE-001

**Created:**
- [x] `platformer_movement` package — GravityScript, JumpScript, PlatformerControlsScript
- [x] `top_down_movement` package — TopDownControlsScript
- [x] `inventory_system` bundle — inventory + gameplay
- [x] `starter_kit` meta-package

---

### PKG-003 — Visual & Effect Scripts
Extract rendering and animation scripts.

**Status:** DONE ✓
**Prerequisites:** CORE-001

**Packages:**
- [ ] `animation-script` — `scripts/animation_script.rb`
- [ ] `effect-script` — `scripts/effect_script.rb`
- [ ] `label-script` — `scripts/label_script.rb`
- [ ] `debug-render-script` — `scripts/debug_render_script.rb`

---

### PKG-004 — Gameplay Scripts
Extract gameplay systems (health, inventory, pickup, damage, etc.).

**Status:** DONE ✓
**Prerequisites:** CORE-001

**Packages:**
- [ ] `health-script` — `scripts/health_script.rb`
- [ ] `inventory-script` — `scripts/inventory_script.rb`
- [ ] `inventory-spec-script` — `scripts/inventory_spec_script.rb`
- [ ] `pickup-script` — `scripts/pickup_script.rb`
- [ ] `collision-damage-script` — `scripts/collision_damage_script.rb`
- [ ] `disable-controls-script` — `scripts/disable_controls_script.rb`
- [ ] `prompt-script` — `scripts/prompt_script.rb`
- [ ] `progress-bar-script` — `scripts/progress_bar_script.rb`

---

### PKG-005 — Persistence Scripts
Extract save data and document store scripts.

**Status:** DONE ✓
**Prerequisites:** CORE-001

**Packages:**
- [ ] `save-data-script` — `scripts/save_data_script.rb`
- [ ] `document-store-script` — `scripts/document_store_script.rb` + `scripts/document_stores_script.rb`

---

### PKG-006 — Quest & Dialogue Scripts
Extract quest and dialogue system scripts.

**Status:** DONE ✓
**Prerequisites:** CORE-001

**Packages:**
- [ ] `quest-script` — `scripts/quest_script.rb`
- [ ] `quest-manager-script` — `scripts/quest_manager_script.rb`
- [ ] `dialogue-script` — `scripts/dialogue_script.rb`
- [ ] `dialogue-manager-script` — `scripts/dialogue_manager_script.rb`
- [ ] `shop-script` — `scripts/shop_script.rb`

---

### PKG-007 — UX Scripts
Extract notification, progress bar, audio, and utility scripts.

**Status:** DONE ✓
**Prerequisites:** CORE-001

**Packages:**
- [ ] `notifications-script` — `scripts/notifications_script.rb`
- [ ] `audio-script` — `scripts/audio_script.rb`
- [ ] `loot-locker-currency-gift-script` — `scripts/loot_locker_currency_gift_script.rb`

---

### PKG-008 — Widgets
Extract all 8 widgets.

**Status:** DONE ✓
**Prerequisites:** CORE-001, PKG-002 through PKG-007

**Packages:**
- [ ] `inventory-widget` — `widgets/inventory_widget.rb` (requires `inventory-script`)
- [ ] `dialogue-widget` — `widgets/dialogue_widget.rb` (requires `dialogue-manager-script`)
- [ ] `shop-widget` — `widgets/shop_widget.rb` (requires `confirmation-widget`, `notification-widget`)
- [ ] `notification-widget` — `widgets/notification_widget.rb`
- [ ] `quest-log-widget` — `widgets/quest_log_widget.rb` (requires `quest-manager-script`)
- [ ] `quest-tracker-widget` — `widgets/quest_tracker_widget.rb` (requires `quest-manager-script`)
- [x] `notification-widget` — `widgets/notification_widget.rb`
- [x] `progress-bar-widget` — `widgets/progress_bar_widget.rb`
- [x] `confirmation-widget` — `widgets/confirmation_widget.rb`
- [ ] `inventory-widget` — `widgets/inventory_widget.rb` (requires `inventory-script`)
- [ ] `dialogue-widget` — `widgets/dialogue_widget.rb` (requires `dialogue-manager-script`)
- [ ] `shop-widget` — `widgets/shop_widget.rb` (requires `confirmation-widget`, `notification-widget`)
- [ ] `quest-log-widget` — `widgets/quest_log_widget.rb` (requires `quest-manager-script`)
- [ ] `quest-tracker-widget` — `widgets/quest_tracker_widget.rb` (requires `quest-manager-script`)

---

### PKG-009 — Feature Bundles
Combine related packages into coherent systems.

**Status:** DONE ✓
**Prerequisites:** PKG-002, PKG-004, PKG-006

**Packages:**
- [ ] `platformer-movement` — `gravity-script` + `jump-script` + `platformer-controls-script`
- [ ] `top-down-movement` — `top-down-controls-script`
- [ ] `inventory-system` — `inventory-script` + `inventory-spec-script` + `inventory-widget` + `notification-widget`
- [ ] `quest-system` — `quest-script` + `quest-manager-script` + `quest-log-widget` + `quest-tracker-widget`
- [ ] `dialogue-system` — `dialogue-script` + `dialogue-manager-script` + `dialogue-widget`

---

### PKG-010 — Meta Packages
Bundles of packages for quick project starts.

**Status:** DONE ✓
**Prerequisites:** PKG-001, PKG-009

**Packages:**
- [ ] `base-game` — `ldtk-loader` + `platformer-movement` + `health-script` + `inventory-system` + `quest-system` + `dialogue-system` + `notifications-script`
- [ ] `platformer-template` — `ldtk-loader` + `platformer-player-script` + `health-script` + `pickup-script`
- [ ] `top-down-template` — `ldtk-loader` + `top-down-player-script` + `health-script` + `inventory-system`
- [ ] `rpg-template` — `ldtk-loader` + `top-down-movement` + `health-script` + `inventory-system` + `quest-system` + `dialogue-system`

---

## Phase 8: Remaining Features

### MISC-001 — Assets in Packages
Handle sprite/audio assets from packages.

**Status:** DONE ✓
**Prerequisites:** CORE-002

**Implemented:**
- Packages install to `packages/{name}/` namespace
  - `packages/{name}/lib/` — main library
  - `packages/{name}/scripts/` — script files
  - `packages/{name}/widgets/` — widget files
  - `packages/{name}/assets/sprites/` — sprite assets
  - `packages/{name}/assets/audio/` — audio assets
  - `packages/{name}/assets/data/` — data files (LDTK, JSON)
- `PathResolver` utility rewrites require/asset references on install
- `Forge.asset_path(package, logical_path)` resolves asset paths at runtime
- `Forge.asset_maps[name]` stores logical→absolute path mapping per package
- Asset map written to `packages/{name}/assets.json` on install

**Example:**
  # In game code:
  sprite_path = Forge.asset_path("ldtk_parser", "sprites/tileset.png")
  # => "packages/ldtk_parser/assets/sprites/tileset.png"

---

### MISC-002 — Package Version History
View all published versions of a package.

**Status:** TODO
**Prerequisites:** BROWSE-002

**Tasks:**
- [ ] Version history page
- [ ] Each version shows: number, date, author, changelog
- [ ] Click version → that version's detail page
- [ ] Download specific version

---

### MISC-003 — Update Notifications
"Update Available" indicators.

**Status:** DONE ✓
**Prerequisites:** CORE-002

**Tasks:**
- [ ] `forge update` CLI equivalent: `Forge.update_packages`
- [ ] Web: "Update Available" badge on outdated packages
- [ ] `GET /api/updates` — check all installed packages against latest
- [ ] `GET /api/packages/:name/latest` — latest version number

---

## Dependency Graph

```
CORE-001 ──────────────────────────────────────────────────────────┐
  │                                                                │
CORE-003 ─┐                                                       │
  │        │                                                       │
CORE-002 ─┴── API-002 ── API-001 ── API-003 ── API-004 ──────────┤
                    │               │               │               │
                   DL-001 ────────┘               │               │
                      │                           │               │
                   DL-002 ──── DL-003             │               │
                      │                           │               │
              BROWSE-001 ── BROWSE-002 ── BROWSE-003             │
                          │                       │               │
                        PUB-001 ── PUB-002 ── PUB-003             │
                          │                                           │
                        AUTH-001 ── AUTH-002                         │
                                                                  │
PKG-001 ─ PKG-002 ─ PKG-003 ─ PKG-004 ─ PKG-005 ─ PKG-006 ─ PKG-007
    │        │        │        │        │        │        │
    └────────┴────────┴────────┴────────┴────────┴────────┴── PKG-008
                                                            │
                                                       PKG-009 ── PKG-010
```

---

## Progress Summary

| Phase | Stories | Done | In Progress | TODO |
|---|---|---|---|---|
| 1: Core Library | 3 | 2 | 0 | 1 |
| 2: API Key System | 4 | 4 | 0 | 0 |
| 3: Website Downloads | 3 | 3 | 0 | 0 |
| 4: Browse & Packages | 3 | 3 | 0 | 0 |
| 5: Publishing | 3 | 3 | 0 | 0 |
| 6: User Accounts | 2 | 2 | 0 | 0 |
| 7: Package Extraction | 10 | 10 | 0 | 0 |
| 8: Remaining Features | 3 | 2 | 0 | 1 |
| **Total** | **33** | **29** | **0** | **4** |
