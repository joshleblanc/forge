# DragonRuby Forge - Product Requirements Document (PRD)

## 1. Project Overview

**Project Name:** DragonRuby Forge

**Description:** DragonRuby Forge is a package management system for the DragonRuby game framework, consisting of a Ruby-based CLI tool for game developers and a web-based backend for package browsing, viewing, authentication, and publishing. The system enables developers to create, share, discover, and install reusable game components (packages) built for DragonRuby.

**Current State:**
- CLI tool exists at `/mnt/c/source/dragonruby/forge/bin/forge` with commands: `new`, `create`, `link`, `publish`, `search`, `info`, `install`, `update`, `remove`, `list`
- Rails backend skeleton exists at `/home/cereal/dev/dragonruby-forge` with minimal configuration
- Local package registry with sample packages (health, floating_health_bar, physics, platformer_controls)

**Build Scope:**
- Complete the web backend with browse, view, authentication, and publishing functionality
- Wire all CLI actions to the backend API
- Implement user authentication (login flow)
- Add version tracking for packages
- Add update functionality with version checking

---

## 2. Goals & Objectives

### Primary Goals

1. **Package Discovery (Browse & Search)**
   - Enable users to browse available packages on a web interface
   - Search and filter packages by name, tag, author, or keyword
   - View package details including version, dependencies, and description

2. **Package Code Viewing**
   - Display package source code in the web interface
   - Syntax-highlighted Ruby code display
   - File browser for package structure

3. **User Authentication**
   - User registration and login flow
   - Secure session management
   - Protect publishing operations with authentication

4. **Package Publishing**
   - Authenticated users can publish packages to the registry
   - Package validation before publishing
   - Version management on publish

5. **Version Tracking**
   - Track all versions of each package
   - Display version history
   - Version comparison view

6. **Update Functionality**
   - Check for package updates via CLI and web
   - Update notifications
   - Dependency resolution for updates

### Success Metrics

- **Browse Page Load Time:** < 2 seconds
- **Package Install Success Rate:** > 99%
- **Authentication Security:** All sensitive operations require valid session
- **Version Integrity:** Each published version is preserved and accessible
- **CLI-Backend Integration:** All 10 CLI commands functional with backend

---

## 3. User Stories

### User Story 1: Package Browser (Anonymous User)

**As a** game developer exploring DragonRuby packages,

**I want** to browse and search for packages on a website,

**So that** I can discover new packages to use in my game projects.

**Acceptance Criteria:**
- [ ] Homepage displays list of all available packages
- [ ] Search bar allows filtering packages by name or keyword
- [ ] Each package card shows: name, version, author, description, tags
- [ ] Clicking a package navigates to package detail page
- [ ] Pagination or infinite scroll for large package lists
- [ ] Filter by tags (e.g., "physics", "ui", "mechanics")

---

### User Story 2: Package Detail & Code Viewer (Anonymous User)

**As a** game developer researching a package,

**I want** to view package details and source code,

**So that** I can understand how the package works before installing.

**Acceptance Criteria:**
- [ ] Package detail page shows: name, latest version, author, description
- [ ] Version selector dropdown shows all available versions
- [ ] Dependencies section lists all required packages with version constraints
- [ ] Scripts section lists all available scripts/classes
- [ ] Tags section displays package categories
- [ ] Code viewer displays package source files with syntax highlighting
- [ ] File tree navigation to browse package structure
- [ ] "Install via CLI" instructions displayed

---

### User Story 3: User Registration & Login (End User)

**As a** game developer who wants to publish packages,

**I want** to create an account and log in,

**So that** I can authenticate and publish my own packages.

**Acceptance Criteria:**
- [ ] Registration form: username, email, password, password confirmation
- [ ] Email validation (format check)
- [ ] Password strength requirements (min 8 chars)
- [ ] Login form: email/username + password
- [ ] "Remember me" checkbox for persistent sessions
- [ ] Logout functionality
- [ ] Session management with secure cookies
- [ ] Password reset flow (optional for MVP)
- [ ] Error messages for invalid credentials

---

### User Story 4: Package Publishing (Authenticated User)

**As a** authenticated package developer,

**I want** to publish my package to the registry,

**So that** other developers can discover and install my package.

**Acceptance Criteria:**
- [ ] Only authenticated users can access publish page
- [ ] Publish form includes: package name, version, description, dragonruby_version, dependencies, scripts, tags
- [ ] Package name validation (unique, format requirements)
- [ ] Version must follow semver format (e.g., 1.0.0)
- [ ] Cannot publish duplicate version of same package
- [ ] Successful publish shows confirmation and package URL
- [ ] Published package appears in browse listing immediately

---

### User Story 5: Package Update (CLI User)

**As a** game developer with installed packages,

**I want** to check for and apply package updates,

**So that** I can get bug fixes and new features.

**Acceptance Criteria:**
- [ ] `forge update` command queries backend for latest versions
- [ ] Displays which packages have updates available
- [ ] Shows current vs. new version number
- [ ] Dependency conflict detection before update
- [ ] Confirmation before applying updates
- [ ] Updates modify forge.lock with new versions
- [ ] Web interface shows "Update Available" badge on outdated packages

---

### User Story 6: Version History (End User)

**As a** package maintainer or consumer,

**I want** to view version history for a package,

**So that** I can see what changed between versions or roll back if needed.

**Acceptance Criteria:**
- [ ] Version history page lists all published versions
- [ ] Each version entry shows: version number, publish date, author
- [ ] Clicking a version shows that version's details
- [ ] Version download links for each version
- [ ] Dependency snapshot per version (versions at time of publish)

---

## 4. Technical Considerations

### Architecture

- **Backend:** Ruby on Rails 8.x (existing skeleton)
- **Database:** PostgreSQL (recommended for production)
- **Authentication:** Custom session-based auth (or Devise)
- **API Design:** RESTful JSON API
- **Frontend:** Rails views with Turbo/Stimulus (or React/Vue SPA)

### API Endpoints Required

```
# Authentication
POST   /api/auth/register
POST   /api/auth/login
DELETE /api/auth/logout
GET    /api/auth/me

# Packages
GET    /api/packages              # List all packages
GET    /api/packages/:name        # Get package details
GET    /api/packages/:name/versions    # List versions
GET    /api/packages/:name/versions/:version  # Specific version
GET    /api/packages/:name/code    # Get package source code
GET    /api/packages/:name/files   # List package files

# Publishing (Authenticated)
POST   /api/packages              # Create new package
PUT    /api/packages/:name        # Update package
POST   /api/packages/:name/versions   # Publish new version

# Updates
GET    /api/updates               # Check for updates
GET    /api/packages/:name/latest # Get latest version
```

### Database Schema (Conceptual)

```ruby
# Users
create_table :users do |t|
  t.string :username
  t.string :email
  t.string :password_digest
  t.timestamps
end

# Packages
create_table :packages do |t|
  t.string :name
  t.references :owner, foreign_key: { to_table: :users }
  t.string :description
  t.timestamps
end

# Package Versions
create_table :package_versions do |t|
  t.references :package
  t.string :version
  t.string :dragonruby_version
  t.json :dependencies
  t.json :scripts
  t.json :tags
  t.text :source_code # or reference to file storage
  t.timestamps
end
```

### CLI Integration

The CLI (`bin/forge`) must be updated to:
- Use backend API instead of local registry.json
- Handle authentication tokens (store securely)
- Make authenticated requests for publishing
- Display appropriate error messages

### Security Considerations

- Passwords must be hashed (bcrypt)
- API authentication via session cookies or tokens
- Rate limiting on publish endpoints
- Input validation and sanitization
- Source code sandboxing (prevent malicious code execution)

### File Storage

- Source code stored in database or file storage (S3, local)
- Package metadata in database
- Consider git-based storage for version history

---

## 5. Out of Scope

The following features are explicitly **NOT** included in this release:

1. **Social Features**
   - User profiles with avatars
   - Comments on packages
   - Ratings or reviews
   - Following package authors

2. **Advanced Package Management**
   - Private packages (visible only to owner)
   - Organization/team accounts
   - Package deprecation workflow

3. **Advanced Search**
   - Fuzzy matching
   - Search analytics
   - Featured/trending packages

4. **Payment/ Monetization**
   - Paid packages
   - Premium subscriptions
   - Revenue sharing

5. **Advanced CLI Features**
   - `forge upgrade` (major version migrations)
   - `forge rollback` (revert to previous version)
   - `forge diff` (show changes between versions)
   - Offline mode / local cache

6. **Integration Features**
   - GitHub OAuth login
   - CI/CD integration
   - Webhook notifications

7. **Documentation System**
   - Package documentation hosting
   - Tutorial viewing within web app

8. **Mobile App**
   - Mobile-responsive is NOT required (browse only on desktop for MVP)

---

## 6. Implementation Priority

### Phase 1: Core Infrastructure (Week 1-2)
- User authentication (register, login, logout)
- Database schema and migrations
- Basic API endpoints

### Phase 2: Package Browse & View (Week 2-3)
- Package listing and search
- Package detail page
- Code viewer with syntax highlighting

### Phase 3: Publishing & Versioning (Week 3-4)
- Package publishing workflow
- Version history and tracking
- Update checking API

### Phase 4: CLI Integration (Week 4-5)
- Wire CLI to backend API
- Authentication flow in CLI
- All 10 commands functional

### Phase 5: Polish (Week 5-6)
- Error handling
- UI/UX improvements
- Testing and bug fixes

---

## 7. Dependencies & Constraints

- **Ruby Version:** 3.2+ (for Rails 8)
- **DragonRuby Version:** 3.0+ (package compatibility)
- **Rails Version:** 8.x (existing skeleton)
- **No External Services:** Self-hosted registry (no GitHub dependency for core functionality)

---

*Document Version: 1.0*  
*Created: February 2026*
