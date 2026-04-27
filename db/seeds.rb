# This file should ensure the existence of records required to run the application in every environment.
# The data can then be loaded with the bin/rails db:seed command.

# Clear existing data
PackageVersion.destroy_all
Package.destroy_all

# Create sample packages
packages = [
  {
    name: "health",
    description: "Health tracking for game entities with damage, healing, and death events. Provides a simple way to add health systems to your game entities with customizable max health, damage, healing, and death callbacks.",
    author: "Forge Community",
    latest_version: "1.0.0",
    tags: ["mechanics", "health", "combat"],
    scripts: ["HealthScript"],
    dependencies: {},
    dragonruby_version: ">= 3.0",
    versions: [
      { version: "1.0.0", description: "Added damage and healing callbacks", dependencies: {} },
      { version: "0.9.0", description: "Initial release", dependencies: {} },
      { version: "0.5.0", description: "Beta release", dependencies: {} }
    ]
  },
  {
    name: "floating_health_bar",
    description: "Visual health bar rendered above entities with health. Displays a customizable health bar that floats above game entities, with support for different colors, sizes, and animations.",
    author: "Forge Community",
    latest_version: "1.0.0",
    tags: ["ui", "health", "visual"],
    scripts: ["FloatingHealthBarScript"],
    dependencies: { "health" => ">= 1.0.0" },
    dragonruby_version: ">= 3.0",
    versions: [
      { version: "1.0.0", description: "Added animation support", dependencies: { "health" => ">= 1.0.0" } },
      { version: "0.8.0", description: "Initial release", dependencies: { "health" => ">= 0.5.0" } }
    ]
  },
  {
    name: "physics",
    description: "Basic physics system with gravity, velocity, and collision detection. Includes rigid body physics, gravity simulation, and simple collision responses for game entities.",
    author: "Forge Community",
    latest_version: "1.0.0",
    tags: ["physics", "mechanics"],
    scripts: ["PhysicsScript"],
    dependencies: {},
    dragonruby_version: ">= 3.0",
    versions: [
      { version: "1.0.0", description: "Added collision detection", dependencies: {} },
      { version: "0.5.0", description: "Basic gravity only", dependencies: {} }
    ]
  },
  {
    name: "platformer_controls",
    description: "Platformer-style keyboard controls with jump and gravity. Provides responsive platformer controls with variable jump height, coyote time, and input buffering.",
    author: "Forge Community",
    latest_version: "1.0.0",
    tags: ["controls", "platformer"],
    scripts: ["PlatformerControlsScript"],
    dependencies: { "physics" => ">= 1.0.0" },
    dragonruby_version: ">= 3.0"
  },
  {
    name: "particle_system",
    description: "Lightweight particle system for explosions, effects, and ambient particles. Create stunning visual effects with customizable particle emitters.",
    author: "DragonDev",
    latest_version: "2.1.0",
    tags: ["visual", "effects", "particles"],
    scripts: ["ParticleEmitter", "Particle"],
    dependencies: {},
    dragonruby_version: ">= 3.0",
    versions: [
      { version: "2.1.0", description: "Performance improvements", dependencies: {} },
      { version: "2.0.0", description: "Added emitter system", dependencies: {} },
      { version: "1.0.0", description: "Basic particles", dependencies: {} }
    ]
  },
  {
    name: "dialog_system",
    description: "Dialog and conversation system for RPGs and story-driven games. Supports branching conversations, character portraits, and text animations.",
    author: "StoryForge",
    latest_version: "1.5.0",
    tags: ["ui", "rpg", "dialog"],
    scripts: ["DialogBox", "ConversationManager"],
    dependencies: {},
    dragonruby_version: ">= 3.0"
  },
  {
    name: "ai_behavior",
    description: "Basic AI behaviors including patrol, chase, flee, and wander. Create intelligent enemies and NPCs with state machine-based behavior trees.",
    author: "GameAI Labs",
    latest_version: "1.2.0",
    tags: ["ai", "gameplay", "enemies"],
    scripts: ["AIController", "PatrolBehavior", "ChaseBehavior"],
    dependencies: {},
    dragonruby_version: ">= 3.0"
  },
  {
    name: "camera_system",
    description: "Smooth camera follow system with pan, zoom, and shake effects. Create professional camera movements with smooth interpolation and boundary constraints.",
    author: "Forge Community",
    latest_version: "1.0.0",
    tags: ["camera", "visual"],
    scripts: ["Camera", "CameraFollow"],
    dependencies: {},
    dragonruby_version: ">= 3.0"
  },
  {
    name: "ldtk_parser",
    description: "Parse and use LDTK (LDtk) level editor files in DragonRuby. Supports levels, layers, entities, tilesets, enums, field instances, and auto-tiles.",
    author: "Forge Community",
    latest_version: "1.0.0",
    tags: ["ldtk", "level-editor", "tilemap", "parser"],
    scripts: ["LdtkLoaderScript"],
    widgets: [],
    dependencies: {},
    dragonruby_version: ">= 3.0",
    versions: [
      { version: "1.0.0", description: "Full LDTK spec support: Root, Level, World, LayerInstance, EntityInstance, Tileset, Enum, and more.", dependencies: {} }
    ]
  },
  {
    name: "ui_components",
    description: "Reusable UI widgets for DragonRuby: toast notifications, progress bars, and confirmation dialogs. No dependencies, drop-in components.",
    author: "Forge Community",
    latest_version: "1.0.0",
    tags: ["ui", "widgets", "notifications", "progress-bar", "dialog"],
    scripts: ["NotificationsScript", "ProgressBarScript", "ConfirmationScript"],
    widgets: ["NotificationWidget", "ProgressBarWidget", "ConfirmationWidget"],
    dependencies: {},
    dragonruby_version: ">= 3.0",
    versions: [
      { version: "1.0.0", description: "Initial release: NotificationWidget, ProgressBarWidget, ConfirmationWidget", dependencies: {} }
    ]
  },
  {
    name: "effects",
    description: "Animation and audio effects. Sprite sheet animations with looping, callbacks, and sound effect playback with overlap support.",
    author: "Forge Community",
    latest_version: "1.0.0",
    tags: ["effects", "animation", "audio", "visual", "sprites"],
    scripts: ["AnimationScript", "AudioScript"],
    widgets: [],
    dependencies: {},
    dragonruby_version: ">= 3.0",
    versions: [
      { version: "1.0.0", description: "Initial release: AnimationScript, AudioScript", dependencies: {} }
    ]
  },
  {
    name: "gameplay",
    description: "Core gameplay systems: save/load data, quests with progress tracking, inventory management, and in-game prompts.",
    author: "Forge Community",
    latest_version: "1.0.0",
    tags: ["gameplay", "inventory", "quests", "rpg", "save", "persistence"],
    scripts: ["SaveDataScript", "QuestScript", "QuestManagerScript", "InventorySpecScript", "InventoryScript", "PromptScript"],
    widgets: [],
    dependencies: {},
    dragonruby_version: ">= 3.0",
    versions: [
      { version: "1.0.0", description: "Initial release: save data, quests, inventory, prompts", dependencies: {} }
    ]
  },
  {
    name: "platformer_movement",
    description: "Complete platformer movement system with gravity, variable jump, coyote time, and input buffering. Works with the physics package.",
    author: "Forge Community",
    latest_version: "1.0.0",
    tags: ["platformer", "movement", "physics", "gameplay", "controls"],
    scripts: ["GravityScript", "JumpScript", "PlatformerControlsScript"],
    widgets: [],
    dependencies: { "physics" => ">= 1.0.0" },
    dragonruby_version: ">= 3.0",
    versions: [
      { version: "1.0.0", description: "Initial release: gravity, jump, platformer controls", dependencies: {} }
    ]
  },
  {
    name: "top_down_movement",
    description: "8-directional top-down movement with WASD and arrow keys, diagonal normalization, and collision handling.",
    author: "Forge Community",
    latest_version: "1.0.0",
    tags: ["top-down", "movement", "controls", "gameplay"],
    scripts: ["TopDownControlsScript"],
    widgets: [],
    dependencies: {},
    dragonruby_version: ">= 3.0",
    versions: [
      { version: "1.0.0", description: "Initial release: 8-directional top-down controls", dependencies: {} }
    ]
  },
  {
    name: "inventory_system",
    description: "Complete inventory system with stacking, item specs, save/load, and shop support. Combines with gameplay package.",
    author: "Forge Community",
    latest_version: "1.0.0",
    tags: ["inventory", "items", "shop", "gameplay", "rpg"],
    scripts: ["InventoryScript", "InventorySpecScript", "SaveDataScript"],
    widgets: [],
    dependencies: { "gameplay" => ">= 1.0.0" },
    dragonruby_version: ">= 3.0",
    versions: [
      { version: "1.0.0", description: "Initial release: full inventory system", dependencies: {} }
    ]
  },
  {
    name: "starter_kit",
    description: "Everything needed to start building a DragonRuby game: level parsing, movement, health, animations, and save data.",
    author: "Forge Community",
    latest_version: "1.0.0",
    tags: ["starter", "meta", "essentials"],
    scripts: [],
    widgets: [],
    dependencies: {
      "ldtk_parser" => ">= 1.0.0",
      "platformer_movement" => ">= 1.0.0",
      "health" => ">= 1.0.0",
      "effects" => ">= 1.0.0",
      "gameplay" => ">= 1.0.0"
    },
    dragonruby_version: ">= 3.0",
    versions: [
      { version: "1.0.0", description: "Initial release: meta-package with essential dependencies", dependencies: {} }
    ]
  },
  {
    name: "utilities",
    description: "Small utility scripts: floating labels, control toggling, dialogue nodes, and currency pickups.",
    author: "Forge Community",
    latest_version: "1.0.0",
    tags: ["utility", "label", "dialogue", "controls", "ui"],
    scripts: ["LabelScript", "DisableControlsScript", "DialogueScript", "LootLockerCurrencyGiftScript"],
    widgets: [],
    dependencies: {},
    dragonruby_version: ">= 3.0",
    versions: [
      { version: "1.0.0", description: "Initial release: labels, controls, dialogue, currency", dependencies: {} }
    ]
  }
]

packages.each do |pkg|
  package = Package.find_or_create_by!(name: pkg[:name]) do |p|
    p.description = pkg[:description]
    p.author = pkg[:author]
    p.latest_version = pkg[:latest_version]
    p.tags = pkg[:tags]
    p.scripts = pkg[:scripts]
    p.widgets = pkg[:widgets] || []
    p.dependencies = pkg[:dependencies]
    p.dragonruby_version = pkg[:dragonruby_version]
  end

  # Auto-discover sample apps under packages/<name>/samples/<sample_name>/
  samples_dir = PackagePackager::PACKAGES_ROOT.join(package.name, "samples")
  if Dir.exist?(samples_dir)
    sample_names = Dir.children(samples_dir).select { |n| File.directory?(File.join(samples_dir, n)) }.sort
    package.update!(samples: JSON.generate(sample_names)) if sample_names.any?
  end

  # Create versions — fall back to a single entry derived from latest_version
  # so every package ends up with at least one packageable version.
  versions_spec = pkg[:versions] || [{ version: pkg[:latest_version], description: pkg[:description], dependencies: pkg[:dependencies] || {} }]
  versions_spec.each_with_index do |v, idx|
      created_at = idx.days.ago
      version_record = package.versions.find_or_create_by(version: v[:version]) do |ver|
        ver.description = v[:description]
        ver.dragonruby_version = pkg[:dragonruby_version]
        ver.dependencies = v[:dependencies]
        ver.scripts = pkg[:scripts]
        ver.widgets = pkg[:widgets] || []
        ver.tags = pkg[:tags]
        ver.created_at = created_at
      end

      # Build and attach the ZIP from packages/<name>/ on disk (if present).
      # Meta-packages with no source dir still get a manifest-only archive so
      # dependency resolution on the client works.
      unless version_record.zip_file.attached?
        begin
          PackagePackager.new(package, version_record).build_and_attach
          src = PackagePackager::PACKAGES_ROOT.join(package.name)
          marker = File.directory?(src) ? "+" : "·"
          puts "  #{marker} packaged #{package.name}@#{version_record.version}"
        rescue => e
          puts "  ! failed to package #{package.name}@#{version_record.version}: #{e.message}"
        end
      end
  end
end

puts "Created #{Package.count} packages with #{PackageVersion.count} versions"
puts "Packaged versions: #{PackageVersion.joins(:zip_file_attachment).count} / #{PackageVersion.count}"
