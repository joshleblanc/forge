# frozen_string_literal: true

# DialogueScript for DragonRuby Forge
# Defines a single dialogue node with branching choices.
# Attach to NPCs alongside DialogueManagerScript.
#
# Usage:
#   npc.add_script(Forge::DialogueScript.new(
#     id: :greeting,
#     text: "Hello, traveler!",
#     choices: [
#       { text: "Shop", next: :shop },
#       { text: "Quest", next: :quest_start, requires: :has_quest },
#       { text: "Goodbye", next: :end }
#     ]
#   ))
#
# Options:
#   id:      Unique dialogue ID (Symbol)
#   text:    The dialogue text
#   choices: Array of choice hashes

class DialogueScript < Forge::Script
  attr :id, :text, :choices

  def init
    opts = normalize_options
    @id = opts[:id]
    @text = opts[:text] || ""
    @choices = opts[:choices] || []
  end

  private

  def normalize_options
    if options.is_a?(Hash)
      options
    else
      { id: options }
    end
  end
end
