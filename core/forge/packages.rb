# forge/packages.rb — bootstrap for a Forge-powered DragonRuby project.
#
# Require this from your `app/main.rb`:
#
#   require "forge/packages"
#
# It loads the Forge base library, the package manager, and every package
# listed in `packages.lock.json`. Add or remove packages with:
#
#   Forge.add_package("package-name")
#   Forge.remove_package("package-name")
#
# (Both rewrite `packages.lock.json`; this file does not need editing.)

# Load the Forge base library (Entity, Process, Game, Camera, UI, Forge::Fs,
# Forge::JSON, Forge::Http, ...).
require_relative "forge"

# Package manager (Forge.add_package, ZipReader, publish, ...).
require_relative "package_manager"

# Path resolver utility used by the package manager when extracting archives.
require_relative "utils/path_resolver"

# Load every installed package described by packages.lock.json.
# Paths are project-relative; on DragonRuby GTK.read_file resolves them to the
# game directory, on MRI we run from the project root so they resolve fine too.
lock_path = "packages.lock.json"
if Forge::Fs.exists?(lock_path)
  lock = Forge::JSON.parse(Forge::Fs.read(lock_path)) || { "packages" => {} }
  (lock["packages"] || {}).each do |name, info|
    manifest    = info["manifest"] || {}
    package_dir = File.join("packages", name)

    # 1. Main library file: packages/<name>/lib/<name>.rb (optional).
    lib_path = File.join(package_dir, "lib", "#{name}.rb")
    if Forge::Fs.exists?(lib_path)
      begin
        require lib_path
      rescue => e
        puts "[Forge] Warning: could not load lib #{name}: #{e.message}"
      end
    end

    # 2. Scripts listed in the manifest.
    (manifest["scripts"] || []).each do |script_name|
      script_path = File.join(package_dir, "scripts", "#{Forge::Utils.underscore(script_name)}.rb")
      if Forge::Fs.exists?(script_path)
        begin
          require script_path
        rescue => e
          puts "[Forge] Warning: could not load script #{script_name}: #{e.message}"
        end
      else
        puts "[Forge] Warning: script not found: #{script_path}"
      end
    end

    # 3. Widgets listed in the manifest.
    (manifest["widgets"] || []).each do |widget_name|
      widget_path = File.join(package_dir, "widgets", "#{Forge::Utils.underscore(widget_name)}.rb")
      if Forge::Fs.exists?(widget_path)
        begin
          require widget_path
        rescue => e
          puts "[Forge] Warning: could not load widget #{widget_name}: #{e.message}"
        end
      else
        puts "[Forge] Warning: widget not found: #{widget_path}"
      end
    end

    # 4. Asset map for runtime path resolution.
    asset_map_path = File.join(package_dir, "assets.json")
    if Forge::Fs.exists?(asset_map_path)
      Forge.asset_maps ||= {}
      Forge.asset_maps[name] = Forge::JSON.parse(Forge::Fs.read(asset_map_path)) || {}
      puts "[Forge] Loaded #{Forge.asset_maps[name].length} asset paths for #{name}"
    end
  end
else
  puts "[Forge] No packages installed yet. Run Forge.add_package(\"package-name\") to install a package."
end
