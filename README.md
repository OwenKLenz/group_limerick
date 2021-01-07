# Group Limerick

**[Play Here!](https://group-limerick.herokuapp.com/)**

## Preface

I built this game as an optional side project at the end of [Launch School](https://launchschool.com/)'s RB175 course on designing Networked Applications.

This is my first attempt at crafting an original web application. The back end is built in Ruby using the Sinatra framework and the front end is built with with my underdeveloped skills in HTML and CSS with a little jQuery thrown in for good measure to facilitate auto-refreshing and some simple hide/show animations.

Note: This app was designed while sheltering in place during the COVID-19 pandemic and my hope is that the game might be a fun diversion for family and friends during these difficult times.

## What is a limerick?

As defined on [literarydevices.net](http://literarydevices.net/limerick):

*Limerick is a comic verse, containing five anapestic (unstressed/unstressed/stressed) lines, in which the first, second, and fifth lines are longer, rhyme together, and follow three metrical feet. The third and fourth lines rhyme together, are shorter, and follow two metrical feet. However, sometimes it may vary, and amphibrachic (unstressed/stressed/unstressed) form can replace anapestic. In fact, it is a bawdy, humorous, or nonsensical verse written in the form of five anapests, with an aabba rhyme scheme. Since it has a special structure and format, it is called fixed or closed form of poetry.*

\- The bawdier and more uncouth, the better.

## What is Group Limerick?

A delightful game that can be played with 2 or more people. Each person concocts the first line of a limerick and then passes the limerick to the person next to them. This process repeats until the limerick is finished, at which point the results are read aloud and hearty laughs are shared.

## Implementing Group Limerick as a web app

The big challenge with Group Limerick was working out how to provide an online multiplayer experience. The stateless nature of HTTP makes it inherently difficult to do things like keeping track of each player's contributions to the game and ensuring that each player is served up the appropriate data at each phase of the game.

The next phase in my learning at Launch School will introduce me to the world of databases, a seemingly excellent solution to the problem of tracking and persisting game state for several players, but for now, I had to devise another solution to allow me to create a shared game state that would persist for the whole game and be accessible by all players.

**Heroku and its Ephemeral File System**

The app is hosted by the cloud application platform, [Heroku](https://www.heroku.com/), which runs apps in small, cloud based containers call Dynos. Each Dyno provides its own file system, similar to those used to store and access files on your average Windows, Mac or Linux based home computer (Dynos run Linux, infact), but with the catch being that the file system is ephemeral. Every 24 hours or so, Heroku resets them, deleting any stored data that isn't a part of the application architecture.

For any application that needs to store user data over the long term, some sort of database is necessary (Amazon Web Services' S3 cloud storage can also be used for static resources such as uploaded images or text files), since this ephemeral file system would result in the loss of user data every day. Thankfully, since the files only need to last as long as a game of Group Limerick, saving the user data directly on the Dyno is a serviceable solution, at least until I'm more fluent with databases.

**Interfacing with Game Data**

I started out storing each relevant piece of game data directly in a players in a player's session cookie. 

- The data consists of:

  1. The path to the gamefile
  2. The player's name
  3. The group name
  4. A list of all players in the game
  5. The collection of limericks
  6. The currrent line being worked on by all players

  7. Any other values necessary for tracking elements of player state unrelated to the game logic

This meant that if, for instance, I wanted to find out if the current line in a player's current limerick was finished, I'd have to write a garbled mess of references and method calls like:

```
session[:limericks][session[:players].find[:player_name]].size == session[:current_line]
```

This quickly became unmanageable, and it became clear that I needed a better way of encapsulating the game data that would provide a cleaner interface for interacting with the data.

I opted to dust off my Object Oriented design chops and create a class, `GameData`, to hold the data. This class provides a clean interface for referencing various game data elements, helper methods for reading and writing data from/to the gamefile and generally allowed me to abstract away alot of the complexity of updating and interacting with the data for each game/player. I also added a `Limerick` class to handle tracking the state and contents of each limerick (ie: Limerick#complete?, Limerick#size).

With this OO structure implemented, the above attempt to determine if a player had submitted their current line could be accomplished with the much cleaner:

```
game_data.current_line_not_submitted?
```

**Creating and Joining Games**

A game is started by one player creating a "New Game". This is done by entering a name for the game and selecting a number of players (2-5). The name entered for the new game serves as a unique identifier for each game's user data that is written to and read from a file by the same name.

- For instance, if the player enters a groupname of "The Salacious Salamanders", a gamefile with the name `the_salacious_salamanders.yml` is created.

With a new game created and a game file for that game saved locally in the Dyno, other players can visit the `/join` page where a list of available games (collected from all uncompleted gamefiles) can be selected from.

As each new player joins, their username is added to the gamefile associated with the game they joined. Once the predetermined number of users has joined, the game begins and each player is forwarded (Automatically. Thanks, jQuery!) to the line entry page.

**Playing the Game**

Each time a line is entered, the submission is written to the gamefile and all other submitted lines are read from the gamefile into each player's `GameData` instance.

Once the last last player submits their line, that player's `GameData` instance calls the `cycle_limericks` method which handles "passing" each limerick to the next player and writes the changes to the gamefile. 

At this point, the app consults (reads from) the gamefile, sees that all players have submitted their lines for their first limerick, and loads the next limerick for each player while displaying the previously submitted lines for that limerick.

This process repeats until all limericks are complete and results are displayed to all players.
