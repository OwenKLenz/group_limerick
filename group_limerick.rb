# Potential Features:
#   Deleting players
#   Passwords to enter games? (probably unnecessary)
#   Changing names
#   Displaying who came up with which line?
#   Download completed limericks feature
#   Possibly more Jquery features (autoreloading?, animating buttons?)

require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'
require 'redcarpet'
require 'pry' if development?
require 'yaml'

require_relative "lib/game_data"

LINE_NAMES = %w(first second third fourth fifth)

configure do
  enable :sessions

  set :session_secret, "secret"

  set :erb, escape_html: true
end

def game_save_dir
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def create_gamefile
  gamefile =
    File.new(File.join(GameData.game_save_dir, formatted_gamefile_name), 'w')

  raw_game_data = { group_name: params[:group_name],
                    group_size: params[:group_size].to_i,
                    players: [params[:player_name]],
                    limericks: generate_limericks,
                    current_line: 1 }
  YAML.dump(raw_game_data, gamefile)
  gamefile.close
end

def invalid_join?(raw_game_data)
  if invalid_player_name?
    true
  elsif raw_game_data[:players].size >= raw_game_data[:group_size].to_i
      session[:message] = "The group \"#{raw_game_data[:group_name]}\" is "\
                          "already full. No new players may join."
    true
  end
end

def set_session_data
  session[:game_data] = GameData.new(params[:group_name],
                                     params[:player_name])
end

def formatted_gamefile_name
  game_name = params[:group_name] || game_data.group_name
  game_name.downcase.tr(" ", "_") + ".yml"
end

# rubocop:disable MultilineMethodCallIndentation
def format_group_name(gamefile_name)
  File.basename(gamefile_name, ".yml").split("_")
                                      .map(&:capitalize)
                                      .join(" ")
end
# rubocop:enable MultilineMethodCallIndentation

def invalid_group_name?
  if params[:group_name].empty?
    session[:message] = "Group names must be one or more characters"
  elsif File.file?(File.join(GameData.game_save_dir, formatted_gamefile_name))
    session[:message] = "Group name already in use."
  elsif params[:group_name] =~ /([^\w\s]|\A\s)/
    session[:message] = "Group names must begin with an alphanumeric character"
  end
end

def invalid_player_name?
  if params[:player_name].strip.empty?
    session[:message] = "Player names must be one or more characters"
  elsif params[:player_name] =~ /\A\s/
    session[:message] = "Player names must begin with an alphanumeric character"
  end
end

def game_data
  session[:game_data]
end

def collect_in_progress_games
  Dir.glob("*", base: GameData.game_save_dir).select do |file|
    game_data = load_gamefile(file)
    game_data[:limericks].any? { |limerick| !limerick.complete? }
  end
end

def generate_limericks
  Array.new(params[:group_size].to_i) do
    Limerick.new
  end
end

def load_gamefile(gamefile=formatted_gamefile_name)
  YAML.load_file(File.join(GameData.game_save_dir, gamefile))
end

helpers do
  def active_games
    in_progress_games = collect_in_progress_games

    in_progress_games.map do |filename|
      format_group_name(filename)
    end
  end

  def last_selection(game)
    "selected" if game == params[:group_name]
  end

  def unfinished_players
    game_data.players.select.with_index do |_, index|
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

  def render_markdown(file_contents)
    headers["Content-Type"] = "text/html"
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

    markdown.render(file_contents)
  end
end

get "/" do
  erb :index
end

get "/new_game" do
  erb :new_game
end

post "/new_game" do
  if invalid_group_name? || invalid_player_name?
    status 422
    erb :new_game
  else
    create_gamefile
    set_session_data
    session[:message] = "The group \"#{params[:group_name]}\" was created!"
    redirect "/play"
  end
end

get "/join" do
  if active_games.empty?
    session[:message] = "No games available. "\
                        "Try creating a <a href='/new_game'>new game</a>."
    redirect "/"
  else
    erb :join_game
  end
end

post "/join" do
  raw_game_data = load_gamefile

  if raw_game_data[:players].include?(params[:player_name])
    set_session_data
    session[:message] = "Welcome #{game_data.player_name}!"
    redirect "/play"
  elsif invalid_join?(raw_game_data)
    status 422
    erb :join_game
  else
    set_session_data
    session[:message] = "Welcome #{game_data.player_name}!"
    game_data.add_player
    game_data.refresh
    redirect "/play"
  end
end

get "/play" do
  game_data.refresh

  if game_data.players.size < game_data.group_size
    erb :waiting_for_players
  elsif game_data.all_limericks_complete?
    erb :finished_limericks
  elsif game_data.current_line_not_submitted?
    erb :line_entry
  else # Waiting on other players
    erb :jeopardy_theme
  end
end

post "/submit" do
  if params[:new_line].empty?
    session[:message] = "It's not going to be much of a limerick if you leave"\
                        "the line blank. <br>Try reading the "\
                        "<a href='/rules'>rules</a> if you need help."
    status 422
    erb :line_entry
  else
    game_data.add_line(params[:new_line])
    game_data.cycle_limericks if game_data.all_player_lines_submitted?
    redirect "/play"
  end
end

get "/rules" do
  erb :rules
end
