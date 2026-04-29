# Forge Library Agent Guide

## Overview

**Forge** is a DragonRuby game framework library providing:
- **Base classes**: Entity, Widget, Script, Game, Camera, FX, Builder
- **Package manager**: Auto-install, load, and manage packages from the Forge registry
- **UI system**: Buttons, panels, labels, dropdowns, progress bars, checkboxes
- **Physics utilities**: Velocity, arrays for physics calculations

## Project Layout

```
├── app/                # Your game code (main.rb is DragonRuby entry point)
├── forge/              # Forge library (managed by Forge.update_forge)
├── packages/           # Installed package source (auto-managed)
├── packages.lock.json  # Installed packages manifest (commit this)
├── api_key.rb          # Your Forge API key (never commit this)
├── metadata/           # DragonRuby metadata
└── samples/            # Example game code (when using starter_kit)
```

## DragonRuby Constraints

### No Regular Expressions
DragonRuby Game Toolkit uses a **limited Ruby runtime** that **does not support regular expressions**. Use these alternatives:

```ruby
# Instead of: string.match(/pattern/)
string.include?(substring)     # Check for substring
string.start_with?("prefix")  # Check prefix
string.end_with?(".suffix")   # Check suffix
string.split(",")             # Split by delimiter
string.index("substring")     # Find position
```

### No eval / metaprogramming
```ruby
# Do not use: eval, instance_eval, class_eval, send (for method names)
# Use explicit method calls instead
```

### Sprite Resolution
- Default: 1280×720 pixels
- Configure in `metadata/game_metadata.txt`

## Documentation

- **DragonRuby docs**: ../docs
- **DragonRuby samples**: ../samples

## Examples

Example packages and usage patterns are located in:
- `packages/*/samples/` — Sample scripts for each package
- `packages/*/lib/*.rb` — Package implementations to reference

## Important Notes

1. **Do not edit `forge/` directory** — it is managed by `Forge.update_forge`
2. **Commit `packages.lock.json`** — ensures reproducible builds
3. **Never commit `api_key.rb`** — already in .gitignore
4. **Use `tick` method as entry point** — DragonRuby calls this each frame
5. **All sprites require explicit filenames** — no dynamic sprite generation

## API Key

Get your API key by:
1. Registering at <https://forge.game>
2. Copying the key from your profile
3. Creating `api_key.rb` with your key, or downloading a project which auto-generates it

## Quick Start

```ruby
# In app/main.rb (first frame only):
Forge.add_package("starter_kit")

# Or in the DragonRuby console:
Forge.add_package("health")
Forge.add_package("ui_components")
```

## Package Development

```ruby
# Publish your own package:
Forge.publish_package(
  name: "my-script",
  version: "1.0.0",
  description: "Does something",
  scripts: ["MyScript"],
  tags: ["gameplay"]
)
```
