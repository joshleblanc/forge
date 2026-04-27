module PackageHelper
  def file_icon(type)
    {
      "config" => "📋",
      "manifest" => "📋",
      "script" => "📜",
      "widget" => "🧩",
      "lib" => "📚",
      "sprite" => "🎨",
      "audio" => "🔊",
      "asset" => "📦",
      "sample" => "🎮",
      "doc" => "📝",
      "file" => "📄"
    }[type] || "📄"
  end

  def folder_icon(name)
    {
      "lib" => "📚",
      "scripts" => "📜",
      "widgets" => "🧩",
      "assets" => "📦",
      "sprites" => "🎨",
      "audio" => "🔊",
      "samples" => "🎮",
      "data" => "🗂",
      "doc" => "📝"
    }[name] || "📁"
  end
end
