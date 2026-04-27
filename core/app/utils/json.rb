# Forge::JSON — JSON helpers for DragonRuby.
#
# DragonRuby's mruby ships `GTK.parse_json` and `GTK.parse_json_file` for
# parsing, but no serializer. This module wraps both and provides a small
# pure-Ruby serializer for `Forge::JSON.generate` / `Forge::JSON.pretty`.
#
#   Forge::JSON.parse(string)     # => Hash / Array / scalar
#   Forge::JSON.parse_file(path)  # via GTK.parse_json_file
#   Forge::JSON.generate(obj)     # compact
#   Forge::JSON.pretty(obj)       # 2-space indented

module Forge
  module JSON
    class << self
      def parse(string)
        return nil if string.nil? || string.empty?
        GTK.parse_json(string)
      end

      def parse_file(path)
        GTK.parse_json_file(path)
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
