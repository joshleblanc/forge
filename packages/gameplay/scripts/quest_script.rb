# frozen_string_literal: true

# QuestScript for DragonRuby Forge
# Defines a single quest with progress tracking and rewards.
# Attach to player entity alongside QuestManagerScript.
#
# Usage:
#   entity.add_script(Forge::QuestScript.new(
#     id: :find_dog,
#     name: "Find the Dog",
#     description: "The elder's dog is lost. Search the forest.",
#     score: 10,
#     rewards: [Forge::QuestScript::Reward.new(name: "gold", quantity: 50)]
#   ))
#
#   # Progress quest from another script:
#   entity.quest_manager_script.progress(:find_dog)

class QuestScript < Forge::Script
  class Reward
    attr_accessor :name, :quantity, :description

    def initialize(name:, quantity: 1, description: "")
      @name = name
      @quantity = quantity
      @description = description
    end
  end

  attr :id, :name, :description, :parent_id, :score, :active, :tracking
  attr :rewards, :children, :expanded, :completed, :completed_at, :index, :required, :completions

  # Options:
  #   id:          Unique quest ID (Symbol or String)
  #   name:        Display name
  #   description: Quest description
  #   parent_id:   Parent quest ID for nested quests (optional)
  #   score:       Point value (optional)
  #   active:      Is quest available? (default: true)
  #   tracking:    Show in tracker? (default: false)
  #   rewards:     Array of Reward objects
  #   index:       Sort order (default: 0)
  #   required:    Steps required to complete (default: 1)
  def init
    opts = normalize_options
    @id = opts[:id] || raise(":id is required")
    @name = opts[:name] || @id.to_s
    @description = opts[:description] || ""
    @parent_id = opts[:parent_id]
    @score = opts[:score] || 0
    @active = opts.fetch(:active, true)
    @tracking = opts.fetch(:tracking, false)
    @rewards = opts[:rewards] || []
    @children = []
    @expanded = false
    @completed = false
    @completed_at = nil
    @claimed_rewards = false
    @index = opts[:index] || 0
    @required = opts[:required] || 1
    @completions = 0
  end

  def leaf?
    @children.empty?
  end

  def branch?
    !@children.empty?
  end

  def progress
    return 1.0 if @completed
    return 0.0 if @required == 0
    [@completions.to_f / @required, 1.0].min
  end

  def progress_percent
    (progress * 100).to_i
  end

  def complete?
    @completed || @completions >= @required
  end

  def done?
    if leaf?
      @completions >= @required
    else
      @children.all? { |c| !c.active || c.complete? }
    end
  end

  def check_completion!
    if !@completed && done?
      @completed = true
      @completed_at = entity&.args&.tick_count || 0
      return true
    end
    false
  end

  # Manually advance quest progress by one step
  def progress!
    return if @completions >= @required
    @completions += 1
    if @completions >= @required
      @completed = true
      @completed_at = entity&.args&.tick_count || 0
    end
  end

  def total_score
    if leaf?
      @completed ? @score : 0
    else
      own = @completed ? @score : 0
      own + @children.sum(&:total_score)
    end
  end

  def has_rewards?
    !@rewards.empty?
  end

  def unclaimed_rewards?
    @completed && has_rewards? && !@claimed_rewards
  end

  def claim_rewards!
    @claimed_rewards = true
    @rewards
  end

  def completed_count
    if leaf?
      @completed ? 1 : 0
    else
      @children.sum(&:completed_count)
    end
  end

  def total_count
    if leaf?
      1
    else
      @children.sum(&:total_count)
    end
  end

  def to_h
    {
      id: @id,
      name: @name,
      description: @description,
      progress: progress,
      progress_percent: progress_percent,
      completed: @completed,
      claimed_rewards: @claimed_rewards
    }
  end

  private

  def normalize_options
    if options.is_a?(Hash)
      options
    else
      # Support positional args: new(id, name, description)
      { id: options }
    end
  end
end
