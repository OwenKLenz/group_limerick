ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative '../group_limerick'

# Still need to test:
#   Funky group names(periods, other punctation, whitespace, etc.)

class GroupLimerickTest < MiniTest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(game_save_dir)
  end

  def teardown
    FileUtils.rm_rf(game_save_dir)
  end

  def session
    last_request.env["rack.session"]
  end

  def create_test_game(group_name: "Test Group 1", player_name: "test player", group_size: 5)
    post "/new_game", { group_name: group_name, player_name: player_name, group_size: group_size }
  end

  def test_index
    get "/"

    assert_equal last_response.status, 200
    assert_includes last_response.body, '<a href="/new_game">Create a New Game</a>'
  end

  def test_new_game_page
    get "/new_game"

    assert_equal last_response.status, 200
    assert_includes last_response.body, '<form action="/new_game" method="post">'
  end

  def test_create_invalid_game
    # Empty name test
    create_test_game(group_name: "")
    assert_includes last_response.body, "Group names must be one or more characters."

    # Name already in use test
    create_test_game
    create_test_game
    assert_includes last_response.body, "Group name already in use."

    # Empty creator name test
    create_test_game(group_name: "Test Group 2", player_name: "")
    assert_includes last_response.body, "Names must be one or more characters."
  end

  def test_create_new_game
    create_test_game

    assert_equal session[:group_name], "Test Group 1"
    assert_equal session[:player_name], "test player"
    assert_equal session[:group_size], 5
    assert File.file?(File.join(game_save_dir, acquire_gamefile_name(session[:group_name])))
    assert_equal session[:message], "Test Group 1 created!"
    assert_equal last_response.status, 302
  end

  def test_invalid_join
    # Test joining full game
    create_test_game(group_size: 1)

    post "/join", { player_name: "Joe", group_name: "Test Group 1" }
    assert_includes last_response.body, "Test Group 1 is already full."

    # Test joining with empty player name
    create_test_game(group_name: "Test Group 2", player_name: "test player", group_size: 2)

    post "/join", { group_name: "Test Group 2", player_name: "" }
    assert_includes last_response.body, "Player names must be one or more characters."
  end

  def test_valid_join
    create_test_game

    # With new player
    post "/join", { group_name: "Test Group 1", player_name: "Joe" }
    assert_equal last_response.status, 302
    assert_equal "Welcome Joe!", session[:message]

    # With existing player
    post "/join", { group_name: "Test Group 1", player_name: "test player" }
    assert_equal last_response.status, 302
    assert_equal "Welcome test player!", session[:message]
  end
end