# frozen_string_literal: true

# Forge::Fs — filesystem abstraction over both DragonRuby's sandboxed FS
# (`GTK.read_file`, `GTK.write_file`, `GTK.list_files`, `GTK.stat_file`,
# `GTK.delete_file`) and MRI's stdlib (`File`, `FileUtils`, `Dir`).
#
# All paths are project-relative on DragonRuby; the engine handles where
# the data actually lives (game directory in dev, sandboxed user dir in
# production). On MRI absolute paths work normally.
#
#   Forge::Fs.read("packages/health/manifest.json")
#   Forge::Fs.write("packages/health/manifest.json", json)
#   Forge::Fs.exists?("packages/health")           # true for files OR directories
#   Forge::Fs.directory?("packages/health")
#   Forge::Fs.mkdir_p("packages/health/scripts")   # no-op on DragonRuby
#                                                  # (write_file auto-creates)
#   Forge::Fs.rm_rf("packages/health")
#   Forge::Fs.list_recursive("packages/health")    # returns relative file paths
#   Forge::Fs.list_recursive("...", glob: "**/*.rb")

module Forge
  module Fs
    DR_RUNTIME = defined?(GTK) && GTK.respond_to?(:read_file)

    class << self
      def read(path)
        if DR_RUNTIME
          GTK.read_file(path)
        else
          File.exist?(path) ? File.read(path) : nil
        end
      end

      def write(path, content)
        if DR_RUNTIME
          GTK.write_file(path, content.to_s)
        else
          require_fileutils
          FileUtils.mkdir_p(File.dirname(path)) unless File.dirname(path).empty?
          File.binwrite(path, content)
        end
      end

      def exists?(path)
        if DR_RUNTIME
          !GTK.stat_file(path).nil?
        else
          File.exist?(path) || File.directory?(path)
        end
      end

      def directory?(path)
        if DR_RUNTIME
          info = GTK.stat_file(path)
          info && info[:file_type] == :directory
        else
          File.directory?(path)
        end
      end

      def file?(path)
        if DR_RUNTIME
          info = GTK.stat_file(path)
          info && info[:file_type] == :regular
        else
          File.file?(path)
        end
      end

      # Ensure the directory exists. On DragonRuby this is a no-op because
      # `GTK.write_file` automatically creates intermediate directories.
      def mkdir_p(path)
        return if DR_RUNTIME
        require_fileutils
        FileUtils.mkdir_p(path)
      end

      # Recursively delete a file or directory tree.
      def rm_rf(path)
        if DR_RUNTIME
          dr_rm_rf(path)
        else
          require_fileutils
          FileUtils.rm_rf(path)
        end
      end

      # Recursively list every regular file under a directory.
      # Returns an Array of paths (relative to `dir`, with forward slashes).
      # Optional `glob:` filters the results — supports a small subset of
      # glob syntax (`*`, `**`, `?`) sufficient for `**/*.rb`-style patterns.
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

      # MRI/DR-agnostic Dir.glob replacement scoped to a directory.
      def glob(dir, pattern)
        list_recursive(dir, glob: pattern).map { |rel| File.join(dir, rel) }
      end

      private

      def walk(root, rel, out)
        listing = if DR_RUNTIME
          GTK.list_files(rel.empty? ? root : File.join(root, rel)) || []
        else
          Dir.entries(rel.empty? ? root : File.join(root, rel)) - %w[. ..]
        end
        listing.each do |name|
          child_rel = rel.empty? ? name : "#{rel}/#{name}"
          child_abs = File.join(root, child_rel)
          if directory?(child_abs)
            walk(root, child_rel, out)
          else
            out << child_rel
          end
        end
      end

      def dr_rm_rf(path)
        info = GTK.stat_file(path)
        return unless info
        if info[:file_type] == :directory
          (GTK.list_files(path) || []).each do |name|
            dr_rm_rf(File.join(path, name))
          end
        end
        GTK.delete_file(path)
      rescue
        # delete_file raises on non-empty dirs and missing files — best-effort.
        nil
      end

      # Convert a small subset of glob syntax to a Regexp.
      #   **   →  .*
      #   *    →  [^/]*
      #   ?    →  [^/]
      #   .    →  literal
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

      def require_fileutils
        return if defined?(::FileUtils)
        require "fileutils"
      end
    end
  end
end
