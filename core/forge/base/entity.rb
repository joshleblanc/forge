# https://github.com/deepnight/gameBase/blob/master/src/game/Entity.hx

module Forge
  class Entity < Process
    include Scriptable
    include Widgetable

    attr_sprite

    ##
    # cx, cy are grid coords
    # xr, yr are ratios
    # xx, yy are cx,cy + xr,xy
    # dx, dy are change in x, y
    attr :cx, :cy, :xr, :yr
    attr :anchor_x, :anchor_y

    attr :squash_x, :squash_y, :scale_x, :scale_y, :flip_horizontally, :flip_vertically

    attr :dx_total, :dy_total, :destroyed, :dir, :visible, :dir, :collidable

    attr :cd, :ucd, :spawned
    attr :all_velocities, :v_base, :v_bump

    attr :animation, :animations

    # Entity Registration System
    # Use Entity.register(:Name, YourClass) to register entity types
    # Then Entity.resolve(:Name) returns the class
    @_entity_registry = {}

    class << self
      attr_accessor :hidden, :collidable

      # Register an entity type by ID (symbol or string)
      # Usage: Entity.register(:Player, PlayerClass)
      def register(id, entity_class)
        @_entity_registry ||= {}
        @_entity_registry[id.to_s] = entity_class
        
        # Also register by class name for backward compatibility
        name = entity_class.name.split("::").last
        @_entity_registry[name] = entity_class if name
        
        entity_class
      end

      # Resolve an entity ID to its class
      # Usage: Entity.resolve(:Player) or Entity.resolve("Player")
      # Falls back to ObjectSpace scan if not in registry (for backward compatibility)
      def resolve(id)
        @_entity_registry ||= {}
        
        # Fast path: check registry first
        resolved = @_entity_registry[id.to_s]
        return resolved if resolved
        
        # Slow path: ObjectSpace scan (backward compatibility)
        scan_and_register(id)
      end

      # Check if an entity type is registered
      def registered?(id)
        @_entity_registry ||= {}
        @_entity_registry.key?(id.to_s)
      end

      # Get all registered entity IDs
      def registered_entities
        @_entity_registry ||= {}
        @_entity_registry.keys.uniq
      end

      def collidable
        self.collidable = true
      end

      def hidden
        self.hidden = true
      end

      private

      # Scan ObjectSpace and cache results for future lookups
      def scan_and_register(id)
        ObjectSpace.each_object(Class) do |c|
          if c.name&.split("::")&.last == id.to_s
            # Cache it for next time
            @_entity_registry ||= {}
            @_entity_registry[id.to_s] = c
            return c
          end
        end
        nil
      end
    end

    # Auto-register this class when subclassed (convention-based)
    def self.inherited(subclass)
      # Don't auto-register anonymous classes or internal classes
      return unless subclass.name
      return if subclass.name.start_with?("_") || subclass.name.include?("::Widgets::")
      return if subclass.name.include?("::Scripts::")
      
      # Register by class name
      name = subclass.name.split("::").last
      register(name, subclass) if name
    end

    def initialize(**opts)
      super(opts[:parent])

      @dir = 1
      @w = opts[:w] || 16
      @h = opts[:h] || 16
      @tile_w = opts[:tile_w] || 16
      @tile_h = opts[:tile_h] || 16

      @anchor_x = opts[:anchor_x] || 0.5
      @anchor_y = opts[:anchor_y] || 0.5

      set_pos_case(opts[:cx] || 0, opts[:cy] || 0)

      @visible = !self.class.instance_variable_get(:@hidden)
      @collidable = !!self.class.instance_variable_get(:@collidable)

      @dx = 0
      @dy = 0

      @spawned = false

      @squash_x = 1
      @squash_y = 1
      @scale_x = 1
      @scale_y = 1

      @flip_vertically = opts[:flip_vertically] || true
      @flip_horizontally = opts[:flip_horizontally] || false

      @cd = Cooldown.new
      @ucd = Cooldown.new

      @all_velocities = Phys::VelocityArray.new
      @v_base = register_new_velocity(0.82)
      @v_bump = register_new_velocity(0.93)

      add_default_scripts!
      add_default_widgets!
    end

    def register_new_velocity(frict)
      v = Phys::Velocity.create_frict(frict)
      @all_velocities.push(v)
      v
    end

    def squash_x=(scale)
      @squash_x = scale
      @squash_y = 2 - scale
    end

    def spawned?
      @spawned
    end

    def squash_y=(scale)
      @squash_x = 2 - scale
      @squash_y = scale
    end

    def shake_s(x_pow, y_pow, t)
      cd.set_s("shaking", t, true)
      @shake_pow_x = x_pow
      @shake_pow_y = y_pow
    end

    def set_pos_case(x, y)
      self.cx = x
      self.cy = y
      self.xr = anchor_x.to_f
      self.yr = anchor_y.to_f
      @spawned = true
    end

    def x
      (xx * 16)
    end

    def x=(new_x)
      self.cx = (new_x / 16).to_i
      self.xr = (new_x % 16) / 16.0
    end

    def y=(new_y)
      self.cy = (new_y / 16).to_i
      self.yr = (new_y % 16) / 16.0
    end

    def y
      (yy * 16)
    end

    def xx
      cx + xr
    end

    def yy
      cy + yr
    end

    def rx
      x
    end

    def ry
      y
    end

    def rw
      (w * scale_x) / squash_x
    end

    def rh
      (h * scale_y) / squash_y
    end

    def on_ground?
      !destroyed? && v_base.dy == 0 && has_collision(cx, cy + 1)
    end

    def destroyed?
      destroyed
    end

    def on_pre_step_x
      send_to_scripts(:on_pre_step_x)
      send_to_widgets(:on_pre_step_x)
    end

    def on_pre_step_y
      send_to_scripts(:on_pre_step_y)
      send_to_widgets(:on_pre_step_y)
    end

    def apply_damage(amt, from = nil)
      send_to_scripts(:on_damage, amt, from)
      send_to_widgets(:on_damage, amt, from)
    end

    # beginning of frame loop - called before any other entity update loop
    def pre_update
      super

      send_to_scripts(:args=, args)
      send_to_widgets(:args=, args)
      send_to_scripts(:pre_update)
      send_to_widgets(:pre_update)

      return if destroyed?


    end

    def center_x
      rect_center_point.x
    end

    def center_y
      rect_center_point.y
    end

    def visible?
      visible
    end

    def show!
      self.visible = true
    end

    def hide!
      self.visible = false
    end

    def tmod
      1
    end

    # Screen position helpers — override these in your game or use a Camera package
    def gx
      x
    end

    def gy
      y
    end

    def dt
      1
    end

    # called after pre_update and update
    # usually used for rendering
    def post_update
      super

      @squash_x += (1 - @squash_x) * [1, 0.2 * tmod].min
      @squash_y += (1 - @squash_y) * [1, 0.2 * tmod].min

      send_to_scripts(:post_update) if server?
      send_to_scripts(:client_post_update) if client?
      send_to_scripts(:local_post_update) if local?

      send_to_widgets(:post_update)

      # args.outputs.sprites << {
      #   x: x,
      #   y: y,
      #   w: w,
      #   h: h,
      #   r: 0, g: 255, b: 0,
      # }
    end

    def dx_total
      @all_velocities.sum_x
    end

    def dy_total
      @all_velocities.sum_y
    end

    def ftime
      $args.state.tick_count
    end

    def init
      send_to_scripts(:args=, args)
      send_to_scripts(:init) if server?
      send_to_scripts(:local_init) if local?
      send_to_scripts(:client_init) if client?
      send_to_widgets(:args=, args)
      send_to_widgets(:init)
    end

    # I'm not going to pretend to know what this does
    def update
      steps = ((dx_total.abs + dy_total.abs) / 0.33).ceil rescue 0
      if steps > 0
        n = 0
        while (n < steps)
          self.xr += dx_total / steps
          on_pre_step_x if dx_total != 0

          while xr > 1
            self.xr -= 1
            self.cx += 1
          end

          while xr < 0
            self.xr += 1
            self.cx -= 1
          end

          self.yr += dy_total / steps

          on_pre_step_y if dy_total != 0

          while yr > 1
            self.yr -= 1
            self.cy += 1
          end

          while yr < 0
            self.yr += 1
            self.cy -= 1
          end

          n += 1
        end
      end

      all_velocities.each(&:update)
      cd.update(tmod)
      ucd.update(tmod)

      send_to_scripts(:update) if server?
      send_to_scripts(:client_update) if client?
      send_to_scripts(:local_update) if local?

      send_to_widgets(:update)
    end

    def shutdown
      send_to_scripts(:on_shutdown)
      send_to_widgets(:on_shutdown)
    end


  end
end
