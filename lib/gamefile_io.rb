module GamefileIO
  def self.create_gamefile
    gamefile = File.new(File.join(game_save_dir, acquire_gamefile_name), 'w')
    limericks = Array.new(params[:group_size].to_i, [])
    game_data = { group_name: params[:group_name],
                  group_size: (params[:group_size].to_i),
                  players: [params[:player_name]],
                  limericks: limericks }
    YAML.dump(game_data, gamefile, indentation: 2)
    gamefile.close
  end

  def self.load_gamefile
    YAML.load_file(File.join(game_save_dir, acquire_gamefile_name))
  end

  def acquire_group_name(game_filename)
    File.basename(game_filename, ".yml").gsub("_", " ").split(" ").map(&:capitalize).join(" ")
  end

  def update_gamefile(game_data)
    updated_data = YAML.dump(game_data)
    File.write(File.join(game_save_dir, acquire_gamefile_name), updated_data)
  end

  def hi
    puts "hi"
  end
end