module Forge
    class LPoint

        attr :cx, :cy, :yr, :xr
        attr_accessor :grid_size, :scale

        def initialize(grid_size: 16, scale: 1)
            @cx = 0
            @cy = 0
            @yr = 0.5
            @xr = 0.5
            @grid_size = grid_size
            @scale = scale
        end

        def cxf
            cx + xr
        end

        def cyf
            cy + yr
        end

        def level_x
            cxf * grid_size
        end

        def level_x=(v)
            set_level_pixel_x(v)
        end

        def level_y
            cyf * grid_size
        end

        def level_y=(v)
            set_level_pixel_y(v)
        end

        def level_x_i
            level_x.to_i
        end

        def level_y_i
            level_y.to_i
        end

        def screen_x
            # Requires scroller info from game — override or use a Camera package
            level_x * scale
        end

        def screen_y
            # Requires scroller info from game — override or use a Camera package
            level_y * scale
        end

        def self.from_case(cx, cy, grid_size: 16)
            new(grid_size: grid_size).set_level_case(cx.to_i, cy.to_i, cx % 1, cy % 1)
        end

        def self.from_case_center(cx, cy, grid_size: 16)
            new(grid_size: grid_size).set_level_case(cx, cy, 0.5, 0.5)
        end

        def self.from_pixels(x, y, grid_size: 16)
            new(grid_size: grid_size).set_level_pixel(x, y)
        end

        def self.from_screen(sx, sy, grid_size: 16, scale: 1)
            new(grid_size: grid_size, scale: scale).set_screen(sx, sy)
        end

        def set_level_case(x, y, xr = 0.5, yr = 0.5)
            self.cx = x
            self.cy = y
            self.xr = xr
            self.yr = yr
            self
        end

        def use_point(other)
            self.cx = other.cx
            self.cy = other.cy
            self.xr = other.xr
            self.yr = other.yr
        end

        def set_screen(sx, sy)
            set_level_pixel(sx / scale, sy / scale)
            self
        end

        def set_level_pixel(x, y)
            set_level_pixel_x(x)
            set_level_pixel_y(y)
            self
        end

        def set_level_pixel_x(x)
            self.cx = (x / grid_size).to_i
            self.xr = (x % grid_size) / grid_size.to_f
            self
        end

        def set_level_pixel_y(y)
            self.cy = (y / grid_size).to_i
            self.yr = (y % grid_size) / grid_size.to_f
            self
        end

        def dist_case(other, a = 0.0, b = 0.0, c = 0.5, d = 0.5)
            if other.is_a?(Entity)
                dx = (cx + xr) - (other.cx + other.xr)
                dy = (cy + yr) - (other.cy + other.yr)
                Math.sqrt(dx * dx + dy * dy)
            elsif other.is_a?(LPoint)
                dx = (cx + xr) - (other.cx + other.xr)
                dy = (cy + yr) - (other.cy + other.yr)
                Math.sqrt(dx * dx + dy * dy)
            else
                dx = (cx + xr) - (other + c)
                dy = (cy + yr) - (b + d)
                Math.sqrt(dx * dx + dy * dy)
            end
        end

        def dist_px(other = nil, b = 0.0)
            if other.is_a?(Entity)
                Math.sqrt((level_x - other.x) ** 2 + (level_y - other.y) ** 2)
            elsif other.is_a?(LPoint)
                Math.sqrt((level_x - other.level_x) ** 2 + (level_y - other.level_y) ** 2)
            else
                Math.sqrt((level_x - other) ** 2 + (level_y - b) ** 2)
            end
        end

        def ang_to(other, b = nil)
            if other.is_a?(Entity)
                Math.atan2((other.cy + other.yr) - cyf, (other.cx + other.xr) - cxf)
            elsif other.is_a?(LPoint)
                Math.atan2(other.cyf - cyf, other.cxf - cxf)
            else
                Math.atan2(b - level_y, other - level_x)
            end
        end
    end
end
