class Game < Forge::Game
  GRID = 32
  SCALE = Forge::Scaler.best_fit_f(1280, 720)

  def user
    @user ||= User.new("local")
  end

  def init
    super

    # Create player
    player = Player.new(parent: self, cx: 5, cy: 5)
    self.s.player = player

    # Create elder NPC
    elder = VillageElder.new(parent: self, cx: 8, cy: 5)

    # Create some floor tiles
    10.times do |x|
      10.times do |y|
        Floor.new(parent: self, cx: x, cy: y)
      end
    end
  end
end
