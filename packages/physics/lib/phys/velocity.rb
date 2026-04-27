# frozen_string_literal: true

# Based on deepnightLibs Velocity: https://github.com/deepnight/deepnightLibs
#
# A 2D velocity vector with friction support.
#
# Usage:
#   vel = Forge::Phys.velocity(5, 0, 0.95)  # Moving right with friction
#   vel.update                              # Apply friction each frame
#   entity.x += vel.x
#   entity.y += vel.y

module Forge
  module Phys
    class Velocity
      CLEAR_THRESHOLD = 0.0005

      attr :id, :x, :y, :frict_x, :frict_y

      def initialize
        self.id = -1
        self.x = 0
        self.y = 0
        self.frict = 1.0
      end

      # Create a new velocity with initial values
      # @param x [Float] initial x velocity
      # @param y [Float] initial y velocity
      # @param frict [Float] friction (0-1, default 1.0)
      # @return [Velocity]
      def self.create_init(x, y, frict = 1.0)
        new.tap do |v|
          v.set(x, y)
          v.frict = frict
        end
      end

      # Create a velocity with just friction (zero velocity)
      # @param frict [Float]
      # @return [Velocity]
      def self.create_frict(frict)
        new.tap { |v| v.frict = frict }
      end

      # Convenience accessor for x (v is a common shorthand)
      def v
        x
      end

      def v=(new_v)
        self.x = new_v
        self.y = new_v
      end

      # Set both friction values at once
      # @param fx [Float]
      # @param fy [Float]
      def set_fricts(fx, fy)
        self.frict_x = fx
        self.frict_y = fy
      end

      # Multiply velocity by separate x/y factors
      # @param fx [Float]
      # @param fy [Float]
      def mul_xy(fx, fy)
        self.x = x * fx
        self.y = y * fy
      end

      # Multiply velocity by a single factor
      # @param f [Float]
      def mul(f)
        self.x = x * f
        self.y = y * f
      end

      def *(f)
        dup.tap { |v| v.mul(f) }
      end

      # Set x and y velocity
      # @param nx [Float]
      # @param ny [Float]
      def set(nx, ny)
        self.x = nx
        self.y = ny
      end

      # Set both x and y to the same value
      # @param v [Float]
      def set_both(v)
        self.x = v
        self.y = v
      end

      # Add to velocity in a direction
      # @param ang [Float] angle in radians
      # @param v [Float] magnitude to add
      def add_ang(ang, v)
        self.x += Math.cos(ang) * v
        self.y += Math.sin(ang) * v
      end

      # Set velocity from angle and magnitude
      # @param ang [Float] angle in radians
      # @param v [Float] magnitude
      def set_ang(ang, v)
        self.x = Math.cos(ang) * v
        self.y = Math.sin(ang) * v
      end

      # Rotate the velocity by an angle
      # @param ang_inc [Float] angle increment in radians
      def rotate(ang_inc)
        old_ang = ang
        d = len

        self.x = Math.cos(old_ang + ang_inc) * d
        self.y = Math.sin(old_ang + ang_inc) * d
      end

      # Clear velocity to zero
      def clear
        self.x = 0
        self.y = 0
      end

      # Add to velocity
      # @param vx [Float]
      # @param vy [Float]
      def add_xy(vx, vy)
        self.x += vx
        self.y += vy
      end

      # Add length to current velocity in current direction
      # @param v [Float] length to add
      def add_len(v)
        l = len
        a = ang
        self.x = Math.cos(a) * (l + v)
        self.y = Math.sin(a) * (l + v)
      end

      # Check if velocity is near zero
      # @return [Boolean]
      def zero?
        x.abs <= CLEAR_THRESHOLD && y.abs <= CLEAR_THRESHOLD
      end

      # Apply friction to velocity
      # @param frict_override [Float] optional override friction value
      def update(frict_override = -1.0)
        if frict_override >= 0
          self.x = x * frict_override
          self.y = y * frict_override
        else
          self.x = x * frict_x
          self.y = y * frict_y
        end

        self.x = 0 if x.abs < CLEAR_THRESHOLD
        self.y = 0 if y.abs < CLEAR_THRESHOLD
      end

      # Horizontal delta (same as x)
      def dx
        x
      end

      # Vertical delta (same as y)
      def dy
        y
      end

      def dx=(new_x)
        self.x = new_x
      end

      def dy=(new_y)
        self.y = new_y
      end

      # Set uniform friction for both axes
      # @param new_frict [Float]
      def frict=(new_frict)
        self.frict_x = new_frict
        self.frict_y = new_frict
      end

      # Get the angle of the velocity vector
      # @return [Float] angle in radians
      def ang
        Math.atan2(y, x)
      end

      # Get the length (magnitude) of the velocity vector
      # @return [Float]
      def len
        Math.sqrt(x * x + y * y)
      end

      # Get the direction on the x axis (-1, 0, or 1)
      # @return [Integer]
      def dir_x
        x == 0 ? 0 : (x > 0 ? 1 : -1)
      end

      # Get the direction on the y axis (-1, 0, or 1)
      # @return [Integer]
      def dir_y
        y == 0 ? 0 : (y > 0 ? 1 : -1)
      end

      def to_s
        "Velocity#{id < 0 ? "" : "#" + id}(#{x.round(2)}, #{y.round(2)})"
      end

      def short_string
        "#{x.round(2)},#{y.round(2)}"
      end
    end
  end
end
