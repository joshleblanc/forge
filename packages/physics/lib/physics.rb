# frozen_string_literal: true

# DragonRuby Forge - Physics Package
# A simple 2D physics engine for DragonRuby games.
#
# Usage:
#   Forge.add_package("physics")
#
# Provides:
#   Forge::Phys::Velocity     - 2D velocity vector with friction
#   Forge::Phys::VelocityArray - Collection of velocity vectors

require_relative "phys/velocity"
require_relative "phys/velocity_array"

module Forge
  module Phys
    class << self
      # Create a new velocity with initial values
      # @param x [Float] initial x velocity
      # @param y [Float] initial y velocity
      # @param frict [Float] friction multiplier (0-1, default 1.0 = no friction)
      # @return [Velocity]
      def velocity(x = 0, y = 0, frict = 1.0)
        Velocity.create_init(x, y, frict)
      end

      # Create a velocity array
      # @return [VelocityArray]
      def velocity_array
        VelocityArray.new
      end
    end
  end
end
