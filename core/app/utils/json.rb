# frozen_string_literal: true

# Minimal JSON wrapper for DragonRuby.
#
# DragonRuby's mruby runtime ships with `GTK.parse_json` and `GTK.parse_json_file`
# for parsing, but has no built-in serializer. This module provides:
#
#   Forge::JSON.parse(string)     # uses GTK.parse_json
#   Forge::JSON.parse_file(path)  # uses GTK.parse_json_file
#   Forge::JSON.generate(obj)     # compact serializer for Hash/Array/String/
#                                 #   Integer/Float/true/false/nil
#   Forge::JSON.pretty(obj)       # 2-space indented variant
#
# Outside DragonRuby (e.g., tooling, tests on MRI) it falls back to the
# stdlib `json` library so callers don't have to care which runtime they're in.

module Forge
  module JSON
    DR_RUNTIME = defined?(GTK) && GTK.respond_to?(:parse_json)

    class << self
      def parse(string)
        return nil if string.nil? || string.empty?
        if DR_RUNTIME
          GTK.parse_json(string)
        else
          require "json" unless defined?(::JSON)
          ::JSON.parse(string)
        end
      end

      def parse_file(path)
        if DR_RUNTIME && GTK.respond_to?(:parse_json_file)
          GTK.parse_json_file(path)
        elsif defined?(Forge::Fs)
          parse(Forge::Fs.read(path))
        else
          parse(File.read(path))
        end
      end

      def generate(obj)
        encode(obj, indent: nil)
      end

      def pretty(obj)
        encode(obj, indent: "  ", level: 0)
      end

      private

      def encode(obj, indent:, level: 0)
        case obj
        when nil       then "null"
        when true      then "true"
        when false     then "false"
        when Integer   then obj.to_s
        when Float     then obj.finite? ? obj.to_s : "null"
        when String    then encode_string(obj)
        when Symbol    then encode_string(obj.to_s)
        when Array     then encode_array(obj, indent: indent, level: level)
        when Hash      then encode_hash(obj,  indent: indent, level: level)
        else
          encode_string(obj.to_s)
        end
      end

      def encode_string(str)
        escaped = str.to_s.gsub(/[\\"\b\f\n\r\t\x00-\x1F]/) do |ch|
          case ch
          when "\\" then '\\\\'
          when '"'  then '\\"'
          when "\b" then '\\b'
          when "\f" then '\\f'
          when "\n" then '\\n'
          when "\r" then '\\r'
          when "\t" then '\\t'
          else
            format('\\u%04x', ch.ord)
          end
        end
        %("#{escaped}")
      end

      def encode_array(arr, indent:, level:)
        return "[]" if arr.empty?
        if indent
          inner = arr.map { |e| (indent * (level + 1)) + encode(e, indent: indent, level: level + 1) }
          "[\n" + inner.join(",\n") + "\n" + (indent * level) + "]"
        else
          "[" + arr.map { |e| encode(e, indent: nil) }.join(",") + "]"
        end
      end

      def encode_hash(hash, indent:, level:)
        return "{}" if hash.empty?
        if indent
          inner = hash.map do |k, v|
            (indent * (level + 1)) + encode_string(k.to_s) + ": " + encode(v, indent: indent, level: level + 1)
          end
          "{\n" + inner.join(",\n") + "\n" + (indent * level) + "}"
        else
          inner = hash.map { |k, v| encode_string(k.to_s) + ":" + encode(v, indent: nil) }
          "{" + inner.join(",") + "}"
        end
      end
    end
  end
end
