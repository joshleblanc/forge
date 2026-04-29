# Forge::Fs — filesystem helpers backed by DragonRuby's sandboxed FS API.
#
# All paths are project-relative. The engine resolves them to the game
# directory in dev and to the platform-appropriate user data dir in
# production. See:
#   https://github.com/DragonRuby/dragonruby-game-toolkit-contrib/blob/master/docs/api/runtime.md#read_file
#
#   Forge::Fs.read("packages/health/manifest.json")
#   Forge::Fs.write("packages/health/manifest.json", json)
#   Forge::Fs.exists?("packages/health")
#   Forge::Fs.directory?("packages/health")
#   Forge::Fs.mkdir_p("packages/health/scripts")  # no-op (write_file auto-creates)
#   Forge::Fs.rm_rf("packages/health")
#   Forge::Fs.list_recursive("packages/health")

module Forge
  module Fs
    class << self
      def read(path)
        GTK.read_file(path)
      end

      def write(path, content)
        GTK.write_file(path, content.to_s)
      end

      def append(path, content)
        GTK.append_file(path, content.to_s)
      end

      def exists?(path)
        !GTK.stat_file(path).nil?
      end

      def directory?(path)
        info = GTK.stat_file(path)
        info && info[:file_type] == :directory
      end

      def file?(path)
        info = GTK.stat_file(path)
        info && info[:file_type] == :regular
      end

      # No-op — DragonRuby's `GTK.write_file` auto-creates intermediate
      # directories, so there's nothing to do. Kept for symmetry with
      # callers that want to express intent.
      def mkdir_p(_path)
      end

      # Recursively delete a file or directory tree.
      def rm_rf(path)
        info = GTK.stat_file(path)
        return unless info
        if info[:file_type] == :directory
          (GTK.list_files(path) || []).each do |name|
            rm_rf(File.join(path, name))
          end
        end
        GTK.delete_file(path)
      rescue
        # `delete_file` raises on non-empty dirs, missing files, etc.
        # Best-effort cleanup; ignore.
        nil
      end

      # Recursively list every regular file under a directory. Returns paths
      # relative to `dir`, with forward slashes.
      def list_recursive(dir)
        return [] unless directory?(dir)
        results = []
        walk(dir, "", results)
        results
      end

      private

      def walk(root, rel, out)
        full = rel.empty? ? root : File.join(root, rel)
        (GTK.list_files(full) || []).each do |name|
          child_rel = rel.empty? ? name : "#{rel}/#{name}"
          child_abs = File.join(root, child_rel)
          if directory?(child_abs)
            walk(root, child_rel, out)
          else
            out << child_rel
          end
        end
      end

    end
  end
end
