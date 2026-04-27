# frozen_string_literal: true

# DisableControlsScript for DragonRuby Forge
# Temporarily disables player controls.
# Sets a cooldown flag that other scripts can check.
#
# Usage:
#   enemy.add_script(Forge::DisableControlsScript.new)
#
#   # Disable controls for 60 frames (1 second at 60fps)
#   entity.disable_controls_script.disable(duration: 60)
#
#   # Re-enable immediately
#   entity.disable_controls_script.enable
#
#   # Check from other scripts:
#   return if entity.cd.has("controls_disabled")
#
# Requires entity to have:
#   cd: cooldown system (Forge::Cooldown)

class DisableControlsScript < Forge::Script
  def init
    @disabled = false
  end

  # Disable player controls for a duration
  # @param duration [Integer] frames (default: 60)
  def disable(duration: 60)
    @disabled = true
    entity.cd.set_s("controls_disabled", duration) if entity.cd
  end

  # Immediately re-enable controls
  def enable
    @disabled = false
    entity.cd.unset("controls_disabled") if entity.cd
  end

  # Toggle disabled state
  def toggle
    if @disabled
      enable
    else
      disable
    end
  end

  def update
    # Check if cooldown expired
    if @disabled && entity.cd && !entity.cd.has("controls_disabled")
      @disabled = false
    end
  end

  def disabled?
    @disabled
  end

  def enabled?
    !@disabled
  end
end
