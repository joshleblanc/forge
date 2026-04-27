# frozen_string_literal: true

# DragonRuby Forge - UI Components Package
# Reusable widgets for DragonRuby: notifications, progress bars, confirmation dialogs.
#
# Usage:
#   Forge.add_package("ui_components")
#
#   # Notification widget (attach to a game manager entity)
#   entity.add_widget(Forge::NotificationWidget)
#   entity.notification_widget.notify("Level complete!", type: :success)
#
#   # Progress bar
#   entity.add_widget(Forge::ProgressBarWidget)
#   entity.progress_bar_widget.set(75, 100)
#   entity.progress_bar_widget.set_percent(0.5)
#
#   # Confirmation dialog
#   entity.add_widget(Forge::ConfirmationWidget)
#   entity.confirmation_widget.confirm(
#     title: "Quit?",
#     message: "Are you sure you want to quit?",
#     on_yes: -> { quit_game },
#     on_no: -> { }
#   )

module Forge
  module Widgets
    # Namespace for UI widgets
  end
end

require_relative "widgets/notification_widget"
require_relative "widgets/progress_bar_widget"
require_relative "widgets/confirmation_widget"
