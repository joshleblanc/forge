# DragonRuby Forge — Gameplan

## The Idea

Forge is two things:

1. **A web app** — browse packages, read code, publish packages
2. **A downloadable base library** — the Forge core, downloaded as a zip, extracted, runs in DragonRuby

**No CLI. No git submodules. No command-line tooling.**

- **Creating a project** → website "New Project" button → downloads base library zip
- **Installing packages** → inside the game, via an in-game package manager (scripts/widgets you add to your game)
- **Publishing packages** → via the website (authenticated)
- **Browsing/searching** → via the website

---

## Architecture Overview

```
forge/                          ← Rails web app (this repo)
  app/                          ← website views, controllers, models
  core/                         ← Forge base library (Ruby project)
    app/
      forge.rb                  ← main require file
      base/
        process.rb
        entity.rb
        user.rb
        scriptable.rb
        widgetable.rb
        script.rb
        widget.rb
      utils/
        cooldown.rb
        delayer.rb
        tweenie.rb
        scheduler.rb
        recyclable_pool.rb
        stat.rb
        l_point.rb
        scaler.rb
        layer.rb
        utils.rb
        serializable.rb
        const.rb
      phys/
        velocity.rb
        velocity_array.rb
      ui/
        theme.rb
        context.rb
        component.rb
        button.rb
        label.rb
      package_manager.rb         ← in-game package manager (add_package, etc.)
    api_key.rb                  ← user-specific API key (generated per download)
    api_key.rb.example           ← template with placeholder key
    .gitignore                  ← api_key.rb ignored by default
    manifest.json                ← for the "New Project" download
    main.rb                      ← minimal DragonRuby entry point
    Gemfile
```

The `core/` directory is the downloadable project. The website's "New Project" button zips it up and serves it.

---

## The Two Core Pieces

### 1. Forge Core (the Ruby project)

**What it is:** A minimal DragonRuby game project that you download and run.

**What's in it:**
- The base library (Process, Entity, User, Script, Widget, Scriptable, Widgetable, utilities, physics, minimal UI)
- A `package_manager.rb` — the in-game package manager
- A `main.rb` — standard DragonRuby entry point
- A `packages/` directory — where installed packages go

**What it does out of the box:**
- Nothing. It's a blank slate. You open it in DragonRuby, it runs an empty game.
- You add packages (via the in-game package manager) to build features.
- The `package_manager.rb` handles fetching packages from the Forge API and installing them into your `packages/` directory.

**The in-game package manager:**

```ruby
# In the DragonRuby console or during development:
Forge.add_package("health-system")
Forge.add_package("platformer-movement")
Forge.add_package("ldtk-loader")

# Or from the website:
# User browses forge, clicks "Add to Project", gets a code snippet:
#   Paste this in your main.rb:
#   require "packages/health-system/scripts/health_script"
```

The package manager is just a script that:
1. Calls `GET /api/packages/:name/versions/latest`
2. Downloads the ZIP from `/api/packages/:name/versions/:version/download`
3. Extracts it into `packages/:name/`
4. Adds require lines to `packages.rb` (auto-generated require file)
5. Persists the install in `packages.lock.json`

**Why this works:** The base library includes everything needed to make HTTP requests and parse JSON. The package manager is a Ruby script, not a binary CLI. No external tools needed.

### 2. Forge Website (the web app)

**What it is:** The browsing, publishing, and project-creation platform.

**Pages:**
- `/` — home, featured packages
- `/packages` — browse all packages, filter by tags
- `/packages/:name` — package detail, code viewer, install instructions
- `/packages/:name/versions/:version` — specific version
- `/download` or `/new` — "New Project" page, downloads the base library zip
- `/publish` — authenticated package publishing
- `/login`, `/register` — auth

---

## Forge Core — What's in the Base

The base library contains the minimum needed to build any game — plus the package manager.

### Tier 1: Core (always included)

```
core/app/
  forge.rb                      # require everything, Forge namespace
  base/
    process.rb                  # Process loop, ROOTS, lifecycle, pause/resume
    entity.rb                   # Entity with grid pos, velocity, collision, registration
    user.rb                     # Player-owning entity
    scriptable.rb               # attach scripts via .script class method
    widgetable.rb               # attach widgets via .widget class method
    script.rb                   # base Script class, lifecycle hooks
    widget.rb                   # base Widget class, z-ordering, positioning
  utils/
    cooldown.rb                 # named-frame cooldowns with pooling
    delayer.rb                  # delayed callbacks (frames, seconds, ms)
    tweenie.rb                  # tweens (17 easing types)
    scheduler.rb                # frame-scheduled coroutines
    recyclable_pool.rb          # object pooling
    stat.rb                     # min/max stat tracker
    l_point.rb                  # level position math helper
    scaler.rb                   # viewport scaling
    layer.rb                    # sprite group layer
    utils.rb                    # string utilities
    serializable.rb             # serialization mixin
    const.rb                    # constants
  phys/
    velocity.rb                 # velocity with friction
    velocity_array.rb           # array of velocities, sums dx/dy
  ui/
    theme.rb                    # color palettes, fonts, sizes
    context.rb                  # component registry, focus
    component.rb                # base UI component
    button.rb                   # button
    label.rb                    # text label
  package_manager.rb            # in-game package manager
  packages.rb                   # auto-generated, requires all installed packages
  packages.lock.json            # installed packages with versions
  api_key.rb                    # user-specific API key (generated on download)
  api_key.rb.example            # template with placeholder key
  .gitignore                    # api_key.rb ignored by default
```

**What's NOT in base (these become packages):**
- Camera — becomes `camera` package
- Fx/Particles — becomes `fx` package
- Full UI library (checkbox, toggle, slider, progress bar, panel, dropdown, radio group, text input) — become `ui-kit` package
- All scripts — become individual packages
- All widgets — become individual packages
- LDTK parser — becomes `ldtk-loader` package

### Tier 2: Package Manager

The `package_manager.rb` is the in-game equivalent of what the CLI would have done:

```ruby
module Forge
  class PackageManager
    def self.add_package(name, version: nil)
      # 1. Fetch package metadata from API
      # 2. Download ZIP
      # 3. Extract to packages/:name/
      # 4. Update packages.rb and packages.lock.json
      # 5. Require the new package
    end

    def self.remove_package(name)
      # 1. Remove from packages/:name/
      # 2. Update packages.rb and packages.lock.json
    end

    def self.update_packages
      # Check all installed packages for newer versions
    end

    def self.list_installed
      # Read packages.lock.json
    end

    def self.publish_package(name:, version:, description:, scripts: [], widgets: [], assets: [], dependencies: [], tags: [])
      # 1. Verify publish access: GET /api/auth/verify with Forge::API_KEY
      # 2. Check can_publish flag — if false, raise "Account required to publish. Visit forge.game to register."
      # 3. POST /api/packages with API key in Authorization header
      # 4. Increment publish_count on ApiKey record (via API response)
      # 5. Return published package info
    end

    def self.search(query)
      # GET /api/packages?q=query — proxy to API
    end
  end
end
```

**All API calls use `Forge::API_KEY`** — read from `api_key.rb`, set by the website on download.
    end

    def self.list_installed
      # Read packages.lock.json
    end
  end
end
```

The Forge API already exists (from the PRD). The package manager just calls it from Ruby.

**No authentication in the base package manager** — authentication is needed for publishing, not installing public packages. The `add_package` method works without login.

For publishing from within the game: separate flow, likely out of scope for MVP.

### Tier 3: Entry Point

`main.rb` in the base:
```ruby
# For a brand new project, this is all you need:
require "app/forge"
require "app/packages"

def tick(args)
  Forge.tick(args)
end
```

The `Forge.tick` method is just:
```ruby
def self.tick(args)
  Forge::Process.update_all(1)
end
```

---

## Packages — How They Work

### Package Structure

Every package is a directory with a manifest:

```
health-system/
  manifest.json          # name, version, description, deps, scripts[], widgets[], assets[]
  scripts/
    health_script.rb
    damage_calculator.rb
  widgets/
    health_bar_widget.rb
  assets/
    heart.png
```

**manifest.json:**
```json
{
  "name": "health-system",
  "version": "1.0.0",
  "description": "Health, damage, invulnerability frames, and death",
  "forge_version": ">=1.0",
  "dependencies": [],
  "scripts": ["HealthScript", "DamageCalculatorScript"],
  "widgets": ["HealthBarWidget"],
  "assets": ["heart.png"],
  "tags": ["gameplay", "rpg"],
  "author": "you"
}
```

### Installing a Package (in-game)

```ruby
# User types in console or calls from code:
Forge.add_package("health-system")
```

What happens:
1. `PackageManager.add_package("health-system")`
2. GET `https://forge.game/api/packages/health-system/versions/latest`
3. Parse manifest, check dependencies
4. Recursively install dependencies
5. GET `https://forge.game/api/packages/health-system/versions/1.0.0/download`
6. Download ZIP
7. Extract to `packages/health-system/`
8. Add `"packages/health-system/scripts/health_script"` to `packages.rb`
9. Add entry to `packages.lock.json`
10. `require "packages/health-system/scripts/health_script"` is now active

### Package Installation Location

```
my-game/
  app/
    forge.rb
    main.rb
    base/           # Forge base library
    packages/       # Installed packages
      health-system/
        manifest.json
        scripts/
      platformer-movement/
        manifest.json
        scripts/
        widgets/
  packages.rb        # auto-generated requires
  packages.lock.json # installed packages with versions
```

### Package Types

| Type | Example | Contents |
|---|---|---|
| Single script | `jump-script` | one script.rb + manifest.json |
| Single widget | `notification-widget` | one widget.rb + manifest.json |
| Feature bundle | `inventory-system` | multiple scripts + widgets + assets |
| Full parser | `ldtk-loader` | 17 parser files + scripts |
| Meta-package | `base-game` | just manifest.json with deps[] |

---

## Website Changes

### New: "New Project" Page (`/new`)

- Hero: "Start building your DragonRuby game with Forge"
- Big button: **"Download Forge Base Library"**
  - Clicking it: generates a zip of the `core/` directory with a unique API key
  - Optionally: name your project (renames directories in the zip)
  - Downloads `my-game.zip`
- Below: "Or browse packages to add to an existing project"

The zip contains everything needed to run — no gem install, no CLI, just extract and open in DragonRuby.

**API key generation on download:**

When the user clicks "Download", the website:
1. Looks up or creates an `ApiKey` record for the user (anonymous if not logged in)
2. Renders the zip with the real API key embedded in `api_key.rb`
3. Serves the zip

If the user is not logged in: an anonymous `User` record is auto-created, the `ApiKey` is tied to it. The user can later register and link the key to their account from the website.

### API Key Authentication

Every downloaded project ships with a pre-authenticated API key. This means users can immediately publish packages without signing in anywhere — the key handles it all.

**`api_key.rb.example`** (the template committed to `core/`):
```ruby
module Forge
  API_KEY = "YOUR_API_KEY"
  API_URL = "https://forge.game/api"
end
```

**`api_key.rb`** (the generated file, substituted into the zip):
```ruby
module Forge
  API_KEY = "fk_live_a1b2c3d4e5f6..."
  API_URL = "https://forge.game/api"
end
```

**`.gitignore`** (in `core/`):
```
# Forge API key — do not commit
api_key.rb
```

**How it works:**
- `package_manager.rb` and any publishing code reads `Forge::API_KEY`
- All API calls include `Authorization: Bearer <API_KEY>` header
- The server validates the key against the `api_keys` table
- `can_publish?` on the `ApiKey` controls whether publishing is allowed — anonymous keys return `false`
- Users can publish directly from the game if they have a registered account key — no browser login required at publish time

**Key benefits:**
1. Zero-friction publishing — download project, write code, `Forge.publish_package(...)`, done (requires registered account key — anonymous keys can only download)
2. No session cookies, no browser sign-in flow at publish time
3. API key is per-download, so download count and publishing credit goes to the right account
4. `api_key.rb` is in `.gitignore` — can't accidentally commit to a public repo
5. Keys can be revoked from the website if compromised

**Anonymous vs registered keys:**
- **Anonymous keys** (no user): can download and install packages, cannot publish
- **Registered keys** (tied to a user account): full access — download, install, publish
- User downloads without logging in → anonymous `User` created → `ApiKey` tied to it
- User registers on forge.game → can claim their anonymous keys and link them to their account, enabling publishing
- Multiple keys allowed per user (one per download)

### Package Detail Page Updates

- **"Add to Project" button** — generates the require line to paste into `packages.rb`
- **"Copy install snippet"** — generates `Forge.add_package("...")` to run in console
- **Code viewer** — browse scripts/widgets in the package, syntax highlighted

### Publish Page

- Upload ZIP or fill form
- Auto-parses manifest from ZIP
- Scripts[] / Widgets[] file picker
- Dependencies[] searchable package selector

---

## Database Model (additions to PRD schema)

```ruby
# ApiKey model (new)
class CreateApiKeys < ActiveRecord::Migration
  def change
    create_table :api_keys do |t|
      t.references :user, foreign_key: true, optional: true
      t.string :key, null: false, unique: true    # "fk_live_..."
      t.string :name                                 # user-facing label, e.g. "my-rpg-2024"
      t.integer :download_count, default: 0
      t.integer :publish_count, default: 0
      t.timestamps
    end
    add_index :api_keys, :key, unique: true
  end
end

class ApiKey < ApplicationRecord
  belongs_to :user, optional: true   # nil = anonymous

  before_validation on: :create do
    self.key ||= "fk_live_#{SecureRandom.hex(24)}"
  end

  def anonymous?
    user.nil?
  end

  def can_publish?
    !anonymous?
  end

  def display_name
    name || (anonymous? ? "Anonymous Project" : user.username)
  end
end

class User < ApplicationRecord
  has_many :api_keys, dependent: :destroy
  has_many :packages, dependent: :destroy
end

# PackageVersion model additions:
class PackageVersion < ApplicationRecord
  # Existing:
  # name, version, dragonruby_version, dependencies, source_code

  # New:
  serialize :scripts, JSON    # ["HealthScript", ...]
  serialize :widgets, JSON    # ["HealthBarWidget", ...]
  serialize :assets, JSON      # [{path: "...", checksum: "..."}]
  serialize :tags, JSON         # ["gameplay", "rpg", ...]

  # For meta-packages (just dependencies, no scripts/widgets):
  attribute :is_meta, :boolean, default: false

  # Convenience: zip file path for download
  def download_path
    "packages/#{package.name}/#{version}.zip"
  end
end

# Package model additions:
class Package < ApplicationRecord
  attribute :is_featured, :boolean, default: false
  attribute :download_count, :integer, default: 0
end
```

**API authentication endpoints:**
```
POST /api/auth/verify
  Body: { "key": "fk_live_..." }
  → 200: { "user_id": 42, "username": "...", "anonymous": false, "can_publish": true }
  → 200: { "user_id": nil, "username": nil, "anonymous": true, "can_publish": false }
  → 401: { "error": "invalid key" }

GET /api/me
  Headers: Authorization: Bearer <API_KEY>
  → 200: { "id": 42, "username": "...", "anonymous": false, "can_publish": true, "api_keys": [...] }
  → 401: { "error": "invalid key" }
```

**Publishing requires a registered account.** Anonymous keys can download and install packages but cannot publish. The `can_publish` flag on the auth response tells the package manager whether publishing is available. If an anonymous user tries to call `Forge.publish_package(...)`, the server returns `403 Forbidden` with a message directing them to the website to claim or create an account.

**Download endpoint:**
```
GET /api/packages/:name/versions/:version/download
→ 200: ZIP file
```

The ZIP contains:
```
health-system/
  manifest.json
  scripts/
    health_script.rb
  widgets/
    health_bar_widget.rb
```

---

## Package List (extracted from hoard)

All 33 scripts and 8 widgets become packages. Here's the full inventory:

### Scripts → Packages

| Package Name | Source Files | Dependencies |
|---|---|---|
| `jump-script` | `scripts/jump_script.rb` | none |
| `gravity-script` | `scripts/gravity_script.rb` | none |
| `platformer-controls-script` | `scripts/platformer_controls_script.rb` | `jump-script` (checks for) |
| `top-down-controls-script` | `scripts/top_down_controls_script.rb` | none |
| `platformer-player-script` | `scripts/platformer_player_script.rb` | `gravity-script`, `jump-script`, `platformer-controls-script`, `health-system`, `notifications-script` |
| `top-down-player-script` | `scripts/top_down_player_script.rb` | `top-down-controls-script`, `health-system`, `notifications-script` |
| `health-script` | `scripts/health_script.rb` | none |
| `inventory-script` | `scripts/inventory_script.rb` | `save-data-script` |
| `inventory-spec-script` | `scripts/inventory_spec_script.rb` | none |
| `pickup-script` | `scripts/pickup_script.rb` | `inventory-script` (checks for) |
| `collision-damage-script` | `scripts/collision_damage_script.rb` | none |
| `animation-script` | `scripts/animation_script.rb` | none |
| `effect-script` | `scripts/effect_script.rb` | none |
| `label-script` | `scripts/label_script.rb` | none |
| `debug-render-script` | `scripts/debug_render_script.rb` | none (dev only) |
| `save-data-script` | `scripts/save_data_script.rb` | none |
| `document-store-script` | `scripts/document_store_script.rb`, `scripts/document_stores_script.rb` | none |
| `ldtk-entity-script` | `scripts/ldtk_entity_script.rb` | `ldtk-loader` |
| `move-to-neighbour-script` | `scripts/move_to_neighbour_script.rb` | `ldtk-loader` |
| `move-to-destination-script` | `scripts/move_to_destination_script.rb` | none |
| `quest-script` | `scripts/quest_script.rb` | none |
| `quest-manager-script` | `scripts/quest_manager_script.rb` | `quest-script` |
| `dialogue-script` | `scripts/dialogue_script.rb` | none |
| `dialogue-manager-script` | `scripts/dialogue_manager_script.rb` | `dialogue-script` |
| `shop-script` | `scripts/shop_script.rb` | none |
| `notifications-script` | `scripts/notifications_script.rb` | none |
| `progress-bar-script` | `scripts/progress_bar_script.rb` | none |
| `prompt-script` | `scripts/prompt_script.rb` | none |
| `disable-controls-script` | `scripts/disable_controls_script.rb` | none |
| `audio-script` | `scripts/audio_script.rb` | none |
| `loot-locker-currency-gift-script` | `scripts/loot_locker_currency_gift_script.rb` | none |

### Widgets → Packages

| Package Name | Source Files | Dependencies |
|---|---|---|
| `inventory-widget` | `widgets/inventory_widget.rb` | `inventory-script` |
| `dialogue-widget` | `widgets/dialogue_widget.rb` | `dialogue-manager-script` |
| `shop-widget` | `widgets/shop_widget.rb` | `confirmation-widget`, `notification-widget` |
| `notification-widget` | `widgets/notification_widget.rb` | none |
| `quest-log-widget` | `widgets/quest_log_widget.rb` | `quest-manager-script` |
| `quest-tracker-widget` | `widgets/quest_tracker_widget.rb` | `quest-manager-script` |
| `confirmation-widget` | `widgets/confirmation_widget.rb` | none |
| `progress-bar-widget` | `widgets/progress_bar_widget.rb` | none |

### Larger Feature Packages

| Package Name | Contents | Dependencies |
|---|---|---|
| `camera` | `camera.rb` | none |
| `fx` | `fx.rb` | none |
| `ui-kit` | `ui/checkbox`, `toggle`, `slider`, `progress_bar`, `panel`, `dropdown`, `radio_group`, `text_input` | `forge-base` (UI base) |
| `ldtk-loader` | all 17 ldtk parser files + `ldtk_entity_script`, `move_to_neighbour_script` | none |
| `platformer-movement` | `gravity-script`, `jump-script`, `platformer-controls-script` | none |
| `top-down-movement` | `top-down-controls-script` | none |
| `inventory-system` | `inventory-script`, `inventory-spec-script`, `inventory-widget` | `save-data-script`, `notification-widget` |
| `quest-system` | `quest-script`, `quest-manager-script`, `quest-log-widget`, `quest-tracker-widget` | none |
| `dialogue-system` | `dialogue-script`, `dialogue-manager-script`, `dialogue-widget` | none |

### Meta Packages

| Package Name | Dependencies |
|---|---|
| `base-game` | `ldtk-loader`, `platformer-movement` (or `top-down-movement`), `health-script`, `inventory-system`, `quest-system`, `dialogue-system`, `notifications-script` |
| `platformer-template` | `ldtk-loader`, `platformer-player-script`, `health-script`, `pickup-script` |
| `top-down-template` | `ldtk-loader`, `top-down-player-script`, `health-script`, `inventory-system` |
| `rpg-template` | `ldtk-loader`, `top-down-movement`, `health-script`, `inventory-system`, `quest-system`, `dialogue-system` |

---

## Implementation Steps

### Step 1: Extract Forge Core
Create the `core/` directory inside the forge repo. Copy files from hoard, update namespaces (`Hoard::` → `Forge::`), get it running in DragonRuby.

**Files to extract:**
1. `process.rb` → `core/app/base/process.rb`
2. `entity.rb` → `core/app/base/entity.rb`
3. `user.rb` → `core/app/base/user.rb`
4. `scriptable.rb` → `core/app/base/scriptable.rb`
5. `widgetable.rb` → `core/app/base/widgetable.rb`
6. `script.rb` → `core/app/base/script.rb`
7. `widget.rb` → `core/app/base/widget.rb`
8. All utils: cooldown, delayer, tweenie, scheduler, recyclable_pool, stat, l_point, scaler, layer, utils, serializable, const
9. phys: velocity, velocity_array
10. UI base: theme, context, component, button, label
11. `package_manager.rb` (new)
12. `main.rb` (minimal)
13. `packages.rb` (auto-generated stub)
14. `packages.lock.json` (empty)
15. `Gemfile` (dragonruby compatible)
16. `api_key.rb.example` (template with `YOUR_API_KEY` placeholder)
17. `.gitignore` (ignores `api_key.rb`)

**Namespace changes:**
- `Hoard::` → `Forge::`
- `Hoard::Scripts::` → `Forge::Scripts::`
- `Hoard::Widgets::` → `Forge::Widgets::`
- `Hoard.config` → `Forge.config`
- `$hoard_ui_theme` → `Forge.config.ui_theme`

**`forge.rb` (main require file):**
```ruby
require_relative "base/process"
require_relative "base/entity"
require_relative "base/user"
require_relative "base/scriptable"
require_relative "base/widgetable"
require_relative "base/script"
require_relative "base/widget"
# utils...
# phys...
# ui...

module Forge
  class << self
    attr_accessor :config

    def configure(&blk)
      @config ||= Config.new
      blk.call(@config) if blk
    end

    def tick(args)
      Process.update_all(1)
    end
  end
end

Forge.configure do |config|
  config.game_class = nil  # user sets this
end
```

**`api_key.rb.example`** (template in `core/`):
```ruby
module Forge
  API_KEY = "YOUR_API_KEY"
  API_URL = "https://forge.game/api"
end
```

**`.gitignore`** (in `core/`):
```
# Forge API key — do not commit
api_key.rb
```

### Step 2: Write the Package Manager
Create `core/app/package_manager.rb`:
- `Forge.add_package(name, version:)` — fetch from API, download ZIP, extract
- `Forge.remove_package(name)` — remove from packages dir
- `Forge.update_packages` — check for updates
- `Forge.list_packages` — read lock file
- `Forge.search_packages(query)` — proxy to API

Handle dependency resolution (topological sort, semver constraints).

### Step 3: Test Core in DragonRuby
Get a minimal game running:
```ruby
# main.rb
require "app/forge"
require "app/packages"

class MyGame < Forge::Entity; end

def tick(args)
  Forge.tick(args)
end
```

### Step 4: Set Up API Key System
Before the download can work:
1. Create `ApiKey` model and migration
2. Add `ApiKey` relationship to `User` model
3. Implement `POST /api/auth/verify` — validates a key, returns user info
4. Implement `GET /api/me` — returns user info given a valid API key in headers
5. Create the anonymous user flow: if no session, create `User.create!(role: :anonymous)`
6. Add key management UI: list keys, revoke keys, rename keys (under account settings)

### Step 5: Set Up Download Endpoint
On the Rails side:
1. Create `GET /new` page
   - Optional project name input
   - "Download" button submits to download action
2. `GET /new/download` action:
   - Find or create `ApiKey` (session user or anonymous user)
   - Copy `core/` to temp dir
   - Render `api_key.rb` from template, substituting real API key
   - Zip the temp dir
   - Stream zip as download
   - Increment `download_count` on the `ApiKey`
3. Update `PackageVersion#download_count` on package download

### Step 6: Package the Existing Scripts/Widgets
For each of the ~40 packages defined above:
1. Create directory in `packages/` (separate from the main repo — stored as records in the DB, files on disk or in S3)
2. Write `manifest.json`
3. Copy files from hoard, update namespaces
4. Upload to forge as a published package

This is a big migration task — do it systematically. Start with the simplest packages first.

### Step 7: Update Package Detail Page
- "Add to Project" button → generates snippet
- "Copy install snippet" → `Forge.add_package("...")`
- Code viewer for scripts/widgets
- Tags display

### Step 8: Wire Publishing (API Key Auth)
- Accept ZIP uploads or form-based publish
- Parse manifest from ZIP
- Store files
- Make available for download
- **Enforce publish permission server-side:**
  - Before creating a package version, validate the API key belongs to a registered user
  - `ApiKey` with `user_id: nil` → return `403 Forbidden`
  - Increment `publish_count` only on successful publish
- Add publish permission check to the download flow:
  - `GET /api/auth/verify` returns `can_publish: true/false`
  - `publish_package` in package_manager checks this before attempting to publish
  - Shows clear error if anonymous key tries to publish

---

## Key Design Decisions

### Why no CLI?
DragonRuby already has a console. The package manager is a Ruby script. Users already know Ruby. Publishing is handled by the API key embedded in the project — no session login, no browser redirect. No new tooling to learn, no platform-specific binaries, no installation friction.

### Why a zip instead of git?
Git submodules require git knowledge and command-line access. ZIP downloads work for everyone, regardless of their setup. Version control is handled by the lock file (`packages.lock.json`), not git.

### Why in-game package manager instead of manual require?
Manual: download ZIP → extract → add require lines → done.
In-game: `Forge.add_package("health-system")` → everything automatic.

Both work. The in-game manager is better UX and teaches users about the package system. But manual installation should always work too — the `packages/` directory is just directories of Ruby files.

### Package discovery
The website is the primary discovery surface. The in-game package manager can also call `Forge.search_packages("health")` to search from inside the game, which proxies to the website API.

### Authentication
No session-based auth in the game. The downloaded project includes a pre-generated API key tied to the user's account (or an anonymous account). Publishing and authenticated reads use `Authorization: Bearer <API_KEY>`. The game never opens a browser or prompts for login.

Anonymous users get an anonymous account with a unique API key. They can register on the website and claim their keys later.

### Assets
Assets in packages (sprites, audio) go into `packages/:name/assets/`. The package manager extracts them there. DragonRuby automatically picks up anything in `app/assets/`, so either:
1. User manually moves assets to `app/assets/`
2. OR `packages/` is auto-required to expose assets (need to handle this — likely require all `packages/*/assets/` subdirs)

For v1: document that users should copy assets manually or move the directory. Simpler.

---

## Immediate Next Step

**Create the `core/` directory.** Start there. Get it running in DragonRuby. Everything else follows from having a working base library to download.

The forge website already has the Rails skeleton. The `core/` directory is new and needs to be built from the hoard extraction.
