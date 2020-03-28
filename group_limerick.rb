# Potential Features
  # Deleting players
  # Passwords to enter games? (probably unnecessary)
  # Changing names

require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'
require 'pry'
require 'psych'

GROUP_NAMES = ["The Prodigious Pirahnas", "The Incontenent Ibexes", "The Salacious Salamanders"]
LINES_IN_A_LIMERICK = 5
configure do
  enable :sessions

  set :session_secret, "secret"
end

def game_save_dir
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def generate_limericks(number)
  Array.new(number, ["", "", "", "", ""])
end

def create_gamefile
  gamefile = File.new(File.join(game_save_dir, acquire_gamefile_name), 'w')
  limericks = Array.new(params[:group_size].to_i, [])
  game_data = { group_name: params[:group_name],
                group_size: (params[:group_size]),
                players: [params[:player_name]],
                limericks: limericks }
  YAML.dump(game_data, gamefile, indentation: 2)
  gamefile.close
end

def acquire_gamefile_name
  game_name = params[:group_name] || group_name
  game_name.downcase.gsub(" ", "_") + ".yml"
end

def acquire_group_name(game_filename)
  File.basename(game_filename, ".yml").gsub("_", " ").split(" ").map(&:capitalize).join(" ")
end

def invalid_group_name?
  if params[:group_name].empty?
    session[:message] = "Group names must be one or more characters."
  elsif File.file?(File.join(game_save_dir, acquire_gamefile_name))
    session[:message] = "Group name already in use."
  end
end

def empty_player_name?
  if params[:player_name].empty?
    session[:message] = "Names must be one or more characters."
  end
end

def update_gamefile(game_data)
  updated_data = YAML.dump(game_data)
  File.write(File.join(game_save_dir, acquire_gamefile_name), updated_data)
end
# Game logic
def all_limericks_completed?
  limericks.all? { |limerick| limerick.size == LINES_IN_A_LIMERICK }
end

def player_line_not_done?

end

# Game data getters
def limericks
  session[:game_data][:limericks]
end

def players
  session[:game_data][:players]
end

def group_size
  session[:game_data][:group_size].to_i
end

def group_name
  session[:game_data][:group_name]
end

helpers do
  def load_gamefile
    YAML.load_file(File.join(game_save_dir, acquire_gamefile_name))
  end

  def active_games
    Dir.glob("*", base: game_save_dir).map do |filename|
      acquire_group_name(filename)
    end
  end
end

get "/" do
  erb :index
end

get "/new_game" do
  erb :new_game
end

post "/new_game" do
  if invalid_group_name? || empty_player_name?
    erb :new_game 
  else
    create_gamefile
    game_data = load_gamefile
    load_session_data(game_data)
    session[:message] = "#{params[:group_name]} created!"
    redirect "/play"
  end
end

get "/join" do
  erb :join_game
end

def invalid_join?(game_data)
  if empty_player_name?
    session[:message] = "Player names must be one or more characters."
  elsif game_data[:players].size >= game_data[:group_size].to_i
    session[:message] = "The group \"#{game_data[:group_name]}\" is already "\
                        "full. No new players may join."
  end
end

def load_session_data(game_data)
  session[:game_data] = game_data
  session[:player_name] = params[:player_name]
  session[:message] = "Welcome #{session[:player_name]}!"
end

post "/join" do
  game_data = load_gamefile

  if game_data[:players].include?(params[:player_name])
    load_session_data(game_data)
    redirect "/play"
  elsif invalid_join?(game_data)
    erb :join_game
  else
    load_session_data(game_data)
    players << params[:player_name]
    update_gamefile(game_data)
    redirect "/play"
  end
end

get "/play" do
  if players.size < group_size
    erb :waiting_for_players
  else
    # load_latest_game_data
    if limericks_completed?
      erb :finished_limericks
    elsif player_line_not_done?
      erb :line_entry
    else
      erb :jeopardy_theme
    end
  end
  # Done in GameEngineClass?
  # IF players < group_size, display "Waiting for players"
  # IF limericks_completed, display all limericks
  # IF player_line_not_submitted, display line entry form with all submitted lines displayed above
  # IF all_player_lines_not_submitted, display "waiting for other players"
  # ELSE (all lines submitted) load next limerick for player
end

post "/submit" do
  # Update game data and cycle limericks if needed
end

# New Game:
#   Create an instance name
#   Determine number of players
#   Doing so should create a gamefile


# Passing limericks:
#   Players start with an empty limerick
#   Write a line and submit
#   Example: 3 Players
#     Player1 STARTS Limerick 0
#     Player2 STARTS Limerick 1
#     Player3 STARTS Limerick 2

#     Player1 GETS Limerick 2
#     Player2 GETS Limerick 0
#     Player3 GETS Limerick 1

#     Player1 GETS Limerick 1
#     Player2 GETS Limerick 2
#     Player3 GETS Limerick 0

#     Player1 GETS Limerick 0
#     Player2 GETS Limerick 1
#     Player3 GETS Limerick 2

#     Player1 GETS Limerick 2 => FINISHES
#     Player2 GETS Limerick 0 => FINISHES
#     Player3 GETS Limerick 1 => FINISHES

#   Each player views their own page
#   Each time a player's page is loaded, check to see if all lines have been received
#   When all lines are submitted, refresh to receive next limerick

#   Maybe create a limerick class?
#     Increment method in a circular 

#   How to track each player's limerick?