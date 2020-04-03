require "simplecov"
SimpleCov.start

ENV["RACK_ENV"] = "testes"

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

  def create_test_game(group_name: "Test Group 1", player_name: "test player", group_size: 2)
    post "/new_game", { group_name: group_name, player_name: player_name, group_size: group_size }
  end

  def test_index
    get "/"

    assert_equal last_response.status, 200
    assert_includes last_response.body, 'Create a New Game</a>'
  end

  def test_new_game_page
    get "/new_game"

    assert_equal last_response.status, 200
    assert_includes last_response.body, '<form action="/new_game" method="post">'
  end

  def test_create_invalid_game
    # Empty name test
    create_test_game(group_name: "")
    assert_includes last_response.body, "Group names must be one or more characters"

    # Name already in use test
    create_test_game
    create_test_game
    assert_includes last_response.body, "Group name already in use."
    # Attempted name remains in input box
    assert_includes last_response.body, "value=\"Test Group 1\""

    # Empty creator name test
    create_test_game(group_name: "Test Group 2", player_name: "")
    assert_includes last_response.body, "Player names must be one or more characters"
  end

  def test_no_games_available
    get "/join"
    assert_equal session[:message], "No games available. Try creating a <a href='/new_game'>new game</a>."
    assert_equal last_response.status, 302
  end

  def test_create_new_game
    create_test_game

    assert_equal game_data.group_name, "Test Group 1"
    assert_equal game_data.player_name, "test player"
    assert_equal game_data.group_size, 2

    assert File.file?(File.join(game_save_dir, "test_group_1.yml"))
    assert_equal session[:message], "The group \"Test Group 1\" was created!"
    assert_equal last_response.status, 302
  end

  def test_invalid_join
    # Test joining full game
    create_test_game(group_size: 1)

    post "/join", { player_name: "Joe", group_name: "Test Group 1" }
    assert_includes last_response.body, "\"Test Group 1\" is already full."
    assert_equal 422, last_response.status

    # Test joining with empty player name
    create_test_game(group_name: "Test Group 2", player_name: "test player", group_size: 2)

    post "/join", { group_name: "Test Group 2", player_name: "" }
    assert_includes last_response.body, "Player names must be one or more characters"
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

  def test_nav_bar
    get "/"
    assert_includes last_response.body, 'New Game</a>'

    get "/new_game"
    assert_includes last_response.body, 'New Game</a>'
  end

  def test_waiting_for_more_players
    create_test_game
    get last_response["Location"]

    assert_includes last_response.body, "1 of 2 players have joined"
  end

  def test_line_entry_form
    create_test_game
    post "/join", { group_name: "Test Group 1", player_name: "test player 2" }

    get last_response["Location"]
    assert_includes last_response.body, "Enter first line:"
  end

  def test_waiting_for_other_player_submissions
    create_test_game(player_name: "Joe")
    post "/join", { group_name: "Test Group 1", player_name: "Steve" }
    post "/submit", new_line: "There once was a monster named Cookie"

    assert_equal last_response.status, 302

    get last_response["Location"]
    assert_includes last_response.body, "Joe is taking their sweet time..."
  end

  def test_game_end_screen
    create_test_game
    post "/join", { group_name: "Test Group 1", player_name: "test player 2" }

    5.times do
      # test player turn
      post "join", { group_name: "Test Group 1", player_name: "test player 2" }
      post "/submit", { new_line: "test line" }

      # test player 2 turn
      post "/join", { group_name: "Test Group 1", player_name: "test player" }
      post "/submit", { new_line: "test line" }
    end

    get last_response["Location"]
    assert_includes last_response.body, "Finished Limericks"
  end

  def test_rules
    get "/rules"
    assert_equal last_response.status, 200
    assert_includes last_response.body, "<li><p>Group Limerick is played with a group of 2-5 players"
  end
end