# frozen_string_literal: true

# QuestManagerScript for DragonRuby Forge
# Collects and manages all QuestScripts on an entity.
# Attach to player entity.
#
# Usage:
#   entity.add_script(Forge::QuestManagerScript.new)
#   entity.add_script(Forge::QuestScript.new(id: :find_dog, name: "Find Dog", ...))
#
#   # Progress from other scripts:
#   entity.quest_manager_script.progress(:find_dog)
#
#   # Query:
#   entity.quest_manager_script.completed?(:find_dog)
#   entity.quest_manager_script.active_quests
#   entity.quest_manager_script.total_score

class QuestManagerScript < Forge::Script
  def init
    @quests = {}      # id -> QuestScript lookup
    @roots = []       # top-level quests (no parent)
    @on_quest_complete = []
    @on_quest_progress = []
    @recently_completed = []

    # Collect all QuestScripts from entity
    collect_quests
  end

  # Get a quest by ID
  # @param id [Symbol, String]
  # @return [QuestScript, nil]
  def quest(id)
    @quests[id.to_sym] || @quests[id.to_s]
  end

  # Get a quest (alias for quest)
  def [](id)
    quest(id)
  end

  # Advance progress on a quest
  # @param id [Symbol, String]
  # @param steps [Integer] number of steps to advance
  # @return [Boolean] true if quest was just completed
  def progress(id, steps = 1)
    q = quest(id)
    return unless q

    q.instance_variable_set(:@completions, q.instance_variable_get(:@completions) + steps)
    q.progress!

    @on_quest_progress.each { |cb| cb.call(q) }

    if q.check_completion!
      @recently_completed << q
      @on_quest_complete.each { |cb| cb.call(q) }
      true
    else
      false
    end
  end

  # Check if a quest is completed
  def completed?(id)
    q = quest(id)
    q&.completed?
  end

  # Check if a quest is active
  def active?(id)
    q = quest(id)
    q&.active && !q&.completed?
  end

  # Get all root quests (no parent)
  def roots
    @roots
  end

  # Get all active quests
  def active_quests
    @roots.select(&:active)
  end

  # Get all completed quests
  def completed_quests
    @quests.values.select(&:completed?)
  end

  # Get quests currently being tracked
  def tracked_quests
    @quests.values.select(&:tracking)
  end

  # Get total score from all completed quests
  def total_score
    @roots.sum(&:total_score)
  end

  # Get recently completed quests (this frame)
  def recently_completed
    completed = @recently_completed.dup
    @recently_completed.clear
    completed
  end

  # Register a callback for quest completion
  # @param &block [Proc] called with (quest)
  def on_quest_complete(&block)
    @on_quest_complete << block
  end

  # Register a callback for quest progress
  # @param &block [Proc] called with (quest)
  def on_quest_progress(&block)
    @on_quest_progress << block
  end

  # Get all quests as a hash
  def to_h
    @quests.transform_values(&:to_h)
  end

  # Serialize all quest data for saving
  def serialize
    @quests.transform_values do |q|
      {
        completions: q.instance_variable_get(:@completions),
        completed: q.instance_variable_get(:@completed),
        claimed_rewards: q.instance_variable_get(:@claimed_rewards),
        completed_at: q.instance_variable_get(:@completed_at)
      }
    end
  end

  # Load quest data from save
  # @param data [Hash] serialized quest data
  def deserialize(data)
    return unless data.is_a?(Hash)

    data.each do |id, state|
      q = quest(id)
      next unless q

      q.instance_variable_set(:@completions, state[:completions] || 0)
      q.instance_variable_set(:@completed, state[:completed] || false)
      q.instance_variable_set(:@claimed_rewards, state[:claimed_rewards] || false)
      q.instance_variable_set(:@completed_at, state[:completed_at])
    end
  end

  private

  def collect_quests
    return unless entity
    return unless entity.respond_to?(:scripts)

    entity.scripts.each do |s|
      next unless s.is_a?(QuestScript)

      @quests[s.id] = s

      if s.instance_variable_get(:@parent_id)
        parent_id = s.instance_variable_get(:@parent_id)
        parent = @quests[parent_id]
        if parent
          parent.children << s
        end
      else
        @roots << s
      end
    end
  end
end
