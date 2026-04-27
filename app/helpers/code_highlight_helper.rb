module CodeHighlightHelper
  KEYWORDS = %w[
    class module def end if elsif else case when unless while until for do
    return yield break next redo retry rescue ensure raise in
    include extend prepend alias undef defined? lambda proc new throw catch
    attr_reader attr_writer attr_accessor attr
    public protected private
    require require_relative load autoload
    puts print p pp gets and or not true false nil
    ENV ARGV __FILE__ __LINE__ __dir__
    frozen_string_literal encoding
    send __send__ instance_variable_get instance_variable_set
    nil? empty? present? blank? is_a? kind_of? respond_to?
    map each select reject reduce inject find detect each_with_index
    times upto downto step each_char each_byte each_line each_with_object
  ].freeze

  def highlight_code(content, language)
    return html_escape(content) unless language == "ruby" || language == "json"

    if language == "ruby"
      highlight_ruby(content)
    elsif language == "json"
      highlight_json(content)
    else
      html_escape(content)
    end
  end

  private

  def highlight_ruby(code)
    result = +""
    code.split(/(\#[^\n]*|"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|:[\w]+|\b(?:0x[\da-fA-F]+|0b[01]+|0o?[0-7]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\b|@@?\w+|\$[a-zA-Z_]\w*|\b[A-Z][a-zA-Z0-9_]*\b|\b[a-zA-Z_]\w*\b|\s+|.)/).each do |token|
      next if token.nil? || token.empty?
      case
      when token.start_with?("#")
        result << %(<span class="comment">#{html_escape(token)}</span>)
      when token.start_with?('"') || token.start_with?("'")
        result << %(<span class="string">#{html_escape(token)}</span>)
      when token.start_with?(":")
        result << %(<span class="symbol">#{html_escape(token)}</span>)
      when KEYWORDS.include?(token)
        result << %(<span class="keyword">#{html_escape(token)}</span>)
      when token =~ /\A0x[\da-fA-F]+|0b[01]+|0o?[0-7]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\z/
        result << %(<span class="number">#{html_escape(token)}</span>)
      when token =~ /\A[A-Z][a-zA-Z0-9_]*\z/ && token !~ /\A[A-Z]{2,}\z/
        result << %(<span class="constant">#{html_escape(token)}</span>)
      when token.start_with?("@") || token.start_with?("$")
        result << %(<span class="variable">#{html_escape(token)}</span>)
      when token =~ /\A[a-zA-Z_]\w*\z/
        result << html_escape(token)
      else
        result << html_escape(token)
      end
    end
    result
  end

  def highlight_json(json_str)
    json_str
      .gsub(/("(?:[^"\\]|\\.)*")(\s*):/) { |m| %(<span class="json-string">#{m[/"[^"]*"/]}</span>:) }
      .gsub(/:(\s*)("(?:[^"\\]|\\.)*")/) { |_, _ws, s| %(:<span class="json-string">#{s}</span>) }
      .gsub(/:(\s*)(true|false)/) { |_, _ws, b| %(: <span class="json-bool">#{b}</span>) }
      .gsub(/:(\s*)(null)/) { |_, _ws, n| %(: <span class="json-null">#{n}</span>) }
      .gsub(/:(\s*)(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)/) { |_, _ws, num| %(: <span class="json-number">#{num}</span>) }
      .gsub(/([{}])/, '<span class="json-punct">\1</span>')
      .gsub(/([\[\],])/, '<span class="json-punct">\1</span>')
  end
end
