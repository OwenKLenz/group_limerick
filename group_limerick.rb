# Todo:

  # Rules Page

#   Reload button

#   deleting finished games
#     Need a way to track when all players have seen limericks

#   Copyright

#   Styling and generally sprucing things up

#   Look into Jquery features (autoreloading?, Hiding completed limericks)



# Potential Features
  # Deleting players
  # Passwords to enter games? (probably unnecessary)
  # Changing names
  # Displaying who came up with which line?

require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'
require 'pry'
require 'psych'

require_relative "lib/game_data"

GROUP_NAMES = ["test", "test"]
# ["The Prodigious Pirahnas",
#                "The Incontenent Ibexes",
#                "The Salacious Salamanders"]

LINE_NAMES = %w(first second third fourth fifth)
LINES_IN_A_LIMERICK = 2

configure do
  enable :sessions

  set :session_secret, "secret"

  set :erb, :escape_html => true
end

def game_save_dir
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def create_gamefile
  gamefile = File.new(File.join(game_save_dir, acquire_gamefile_name), 'w')
 
  raw_game_data = { group_name: params[:group_name],
                    group_size: (params[:group_size].to_i),
                    players: [params[:player_name]],
                    limericks: [Limerick.new],
                    current_line: 1 }
  YAML.dump(raw_game_data, gamefile, indentation: 2)
  gamefile.close
end

def invalid_join?(raw_game_data)
  if empty_player_name?
    session[:message] = "Player names must be one or more characters."
  elsif raw_game_data[:players].size >= raw_game_data[:group_size].to_i
    session[:message] = "The group \"#{raw_game_data[:group_name]}\" is "\
                        "already full. No new players may join."
  end
end

def empty_line?
  if params[:new_line].empty?
    session[:message] = "What do you think you're doing? You can't submit an "\
                        "empty line! Try reading the "\
                        "<a href='/rules'>rules</a> you nincompoop!"
  end
end

def set_session_data
  session[:game_data] = GameData.new(params[:group_name], params[:player_name])
  session[:message] = "Welcome #{game_data.player_name}!"
end

  def acquire_gamefile_name
    game_name = params[:group_name] || game_data.group_name
  game_name.downcase.gsub(" ", "_") + ".yml"
end

def acquire_group_name(gamefile_name)
  File.basename(gamefile_name, ".yml").gsub("_", " ").split(" ").map(&:capitalize).join(" ")
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

def game_data
  session[:game_data]
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

  def set_selected(game)
    "selected" if game == params[:group_name]
  end

  def unfinished_players
    game_data.players.select.with_index do |player, index|
      game_data.limericks[index].size < game_data.current_line
    end
  end

  def format_unfinished_players
    waiting_on = unfinished_players

    case waiting_on.size
    when 1
      waiting_on.first + " is"
    when 2
     waiting_on.join(" and ") + " are"
    else
      waiting_on[0..-2].join(", ") + " and " + waiting_on[-1] + " are"
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
    status 422
    erb :new_game 
  else
    create_gamefile
    set_session_data
    session[:message] = "#{params[:group_name]} created!"
    redirect "/play"
  end
end

get "/join" do
  erb :join_game
end

post "/join" do
  raw_game_data = load_gamefile

  if raw_game_data[:players].include?(params[:player_name])
    set_session_data
    redirect "/play"
  elsif invalid_join?(raw_game_data)
    status 422
    erb :join_game
  else
    set_session_data
    game_data.add_player(params[:player_name], params[:group_name])
    game_data.refresh
    redirect "/play"
  end
end

get "/play" do
  game_data.refresh

  if game_data.players.size < game_data.group_size
    erb :waiting_for_players
  else
    if game_data.all_limericks_complete?
      erb :finished_limericks
    elsif !game_data.current_line_submitted?
      erb :line_entry
    else # Waiting on other players
      erb :jeopardy_theme
    end
  end
end


post "/submit" do
  if empty_line?
    status 422
    erb :line_entry
  else
    game_data.add_line(params[:new_line])
    game_data.cycle_limericks if game_data.all_player_lines_submitted?
    redirect "/play" 
  end
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