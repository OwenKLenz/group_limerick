require 'yaml'
require 'pry'
require_relative "limerick"

class GameData
  attr_accessor :line_completed
  attr_reader :players, :limericks, :group_size, :group_name, :gamefile_path

  def initialize(group_name, player_name, line_completed=false)
    @gamefile_path = GameData.generate_gamefile_path(group_name)

    gamefile_data = YAML.load_file(@gamefile_path)
    @player_name = player_name
    @group_name = gamefile_data[:group_name]
    @group_size = gamefile_data[:group_size]
    @players = gamefile_data[:players]
    @limericks = gamefile_data[:limericks]
    @line_completed = line_completed

    @game_data = gamefile_data
  end

  def self.load_gamefile(group_name)
    YAML.load_file(self.generate_gamefile_path(group_name))
  end

  def cycle_limericks
    @limericks.unshift(@limericks.pop)
  end

  def all_limericks_complete?
    @limericks.all?(&:complete?)
  end

  def line_done?
    @line_completed
  end

  def self.add_player(player_name, group_name)
    gamefile_data = self.load_gamefile(group_name)

    gamefile_data[:players] << player_name
    gamefile_data[:limericks] << Limerick.new

    formatted_data = YAML.dump(gamefile_data)
    File.write(self.generate_gamefile_path(group_name), formatted_data)
  end

  def refresh
    initialize(@group_name, @player_name, @line_completed)
  end

  def to_s # for debugging
    "<strong>Group Name:</strong> #{@group_name}<br><strong>Group Size:</strong> #{@group_size}<br>"\
    "<strong>Players:</strong> #{@players}<br><strong>Limericks:</strong> #{@limericks}<br>"\
    "<strong>File Path:</strong> #{@gamefile_path}"
  end

  def self.generate_gamefile_path(group_name)
    file_name = group_name.downcase.gsub(" ", "_") + ".yml"
    File.join(GameData.game_save_dir, file_name)
  end

  private

  def self.game_save_dir
    if ENV["RACK_ENV"] == "test"
      File.expand_path("../../test/data", __FILE__)
    else
      File.expand_path("../../data", __FILE__)
    end
  end
end

# Testing GameData objects

# p YAML.load_file("../data/test.yml")

# data = GameData.new({:group_name=>"test", :group_size=>5, :players=>["owen", "Steve"], :limericks=>[]})

# data.add_player("Fred")
# data.update_gamefile
# p data

# p YAML.load_file("../data/test.yml")