# frozen_string_literal: true

module Forge
  module Phys
    # A collection of Velocity objects with physics operations.
    #
    # Usage:
    #   velocities = Forge::Phys.velocity_array
    #   velocities << Forge::Phys.velocity(5, 0)
    #   velocities << Forge::Phys.velocity(0, 3)
    #
    #   entity.x += velocities.sum_x
    #   entity.y += velocities.sum_y
    #   velocities.mul_all(0.9)  # Apply friction

    class VelocityArray < Array
      # Remove a velocity from the collection
      # @param v [Velocity]
      def remove(v)
        delete(v)
      end

      # Sum of all x velocities
      # @return [Float]
      def sum_x
        sum(&:x)
      end

      # Sum of all y velocities
      # @return [Float]
      def sum_y
        sum(&:y)
      end

      # Multiply all velocities by a factor
      # @param f [Float]
      # @return [Float] total sum before multiplication (for chaining)
      def mul_all(f)
        reduce(0) { |sum, vel| sum + vel.mul(f) }
      end

      # Multiply all x velocities
      # @param f [Float]
      # @return [Float]
      def mul_all_x(f)
        reduce(0) { |sum, vel| sum + vel.mul_xy(f, 1) }
      end

      # Multiply all y velocities
      # @param f [Float]
      # @return [Float]
      def mul_all_y(f)
        reduce(0) { |sum, vel| sum + vel.mul_xy(1, f) }
      end

      # Clear all velocities to zero
      def clear_all
        each(&:clear)
      end

      # Remove all zero velocities from the collection
      def remove_zeroes
        reject!(&:zero?)
      end

      # Update all velocities (apply friction)
      # @param frict_override [Float] optional friction override
      def update_all(frict_override = -1.0)
        each { |v| v.update(frict_override) }
      end
    end
  end
end
