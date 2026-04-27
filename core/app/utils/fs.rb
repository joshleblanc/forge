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
#   Forge::Fs.list_recursive("packages/health", glob: "**/*.rb")

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
      # relative to `dir` (forward slashes). Optional `glob:` filters
      # results — supports `**`, `*`, `?`.
      def list_recursive(dir, glob: nil)
        return [] unless directory?(dir)
        results = []
        walk(dir, "", results)
        if glob
          re = glob_to_regex(glob)
          results.select! { |rel| !!(rel =~ re) }
        end
        results
      end

      # Project-aware Dir.glob replacement: returns full paths joined with `dir`.
      def glob(dir, pattern)
        list_recursive(dir, glob: pattern).map { |rel| File.join(dir, rel) }
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

      # Convert a small subset of glob syntax to a Regexp.
      #   **   →  .*
      #   *    →  [^/]*
      #   ?    →  [^/]
      def glob_to_regex(pattern)
        re = +""
        i = 0
        while i < pattern.length
          c = pattern[i]
          if c == "*" && pattern[i + 1] == "*"
            re << ".*"
            i += 2
            i += 1 if pattern[i] == "/"
          elsif c == "*"
            re << "[^/]*"
            i += 1
          elsif c == "?"
            re << "[^/]"
            i += 1
          elsif "().[]+^$|\\".include?(c)
            re << "\\" << c
            i += 1
          else
            re << c
            i += 1
          end
        end
        Regexp.new("\\A" + re + "\\z")
      end
    end
  end
end
