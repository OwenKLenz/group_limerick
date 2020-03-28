require_relative "limerick"

class GameData
  attr_reader :players, :limericks

  def initialize
    @group_name
    @group_size
    @players = []
    @limericks = []
  end

  def add_player(player_name)
    @limericks << Limerick.new
    @players << player_name
  end

  def cycle_limericks
    @limericks.unshift(@limericks.pop)
  end

  def all_limericks_complete?
    @limericks.all?(&:complete?)
  end
end