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
  }
]

packages.each do |pkg|
  package = Package.find_or_create_by!(name: pkg[:name]) do |p|
    p.description = pkg[:description]
    p.author = pkg[:author]
    p.latest_version = pkg[:latest_version]
    p.tags = pkg[:tags]
    p.scripts = pkg[:scripts]
    p.dependencies = pkg[:dependencies]
    p.dragonruby_version = pkg[:dragonruby_version]
  end
  
  # Create versions if specified
  if pkg[:versions]
    pkg[:versions].each_with_index do |v, idx|
      created_at = idx.days.ago
      package.versions.find_or_create_by(version: v[:version]) do |ver|
        ver.description = v[:description]
        ver.dragonruby_version = pkg[:dragonruby_version]
        ver.dependencies = v[:dependencies]
        ver.scripts = pkg[:scripts]
        ver.tags = pkg[:tags]
        ver.created_at = created_at
      end
    end
  end
end

puts "Created #{Package.count} packages with #{PackageVersion.count} versions"
